use MooseX::Declare;
use Method::Signatures::Modifiers;

class API::Module::Handler
{
    use API::Config;
    use API::Log qw(:ALL);
    use Class::Load qw(:all);
    use Constants;
    use Try::Tiny;
    use Util::Hash;
    use Util::String;

    # list of modules loaded
    # the only reason that this is a hash instead of an array
    # is for easier lookup without having to loop
    has 'modules'   => (
        default     => sub { {} },
        is          => 'rw',
        isa         => 'HashRef',
    );

    # module aliases
    has 'aliases'   => (
        default     => sub { {} },
        is          => 'rw',
        isa         => 'HashRef',
    );

    # module settings
    has 'settings'  => (
        default     => sub { {} },
        is          => 'rw',
        isa         => 'HashRef',
    );

    method autoload_aliases
    {
        open my $fh, '<', $sophia::CONFIGURATIONS{ALIAS_DB}
            or _log('sophia', "Unable to open alias database for reading: $!");

        LINE: while (my $line = <$fh>)
        {
            chomp($line);
            next LINE   if ($line =~ /\A\s*\z/);   # skip empty lines

            my ($key, $value) = split(' ', $line);

            $self->aliases->{$key} = $value;
        }

        close $fh;

        return;
    }

    method autoload_modules
    {
        my $modules_config_file = $sophia::CONFIGURATIONS{MODULES_AUTOCONF} or return;
        return unless -e $modules_config_file;

        open my $fh, '<', $modules_config_file
            or _log('sophia', "Cannot open modules autoload config file for reading: $!");

        LINE: while (my $line = <$fh>)
        {
            chomp($line);

            # if the line is formatted: loadmodule module
            if ($line =~ /\A\s*loadmodule\s+([^ ]+)/)
            {
                $self->load_module($1);
            }
        }

        close $fh;

        $self->autoload_settings;

        return;
    }

    method autoload_settings
    {
        my $yaml = API::Config->parse_yaml_config($sophia::CONFIGURATIONS{MODULES_CONFIG});

        for my $block (@$yaml)
        {
            while (my ($key, $value) = each %$block)
            {
                $self->settings->{$key} = $value;
            }
        }

        return;
    }

    method load_module ($module)
    {
        (my $module_path = $module) =~ s/::/\//g;
        my $modules_dir = $sophia::BASE{MODULES};

        return unless -e "$modules_dir/$module_path.pm";

        try
        {
            my $fd = load_class($module);
            $self->modules->{$module} = TRUE;

            _log('sophia', "[MODULE] modules/$module_path.pm successfully loaded.");
            return TRUE;
        }
        catch
        {
            _log('sophia', "[MODULE] modules/$module_path.pm failed to load: $_");
        };

        return FALSE;
    }

    method process_command ($event)
    {
        my $command = $self->resolve_command($event->command);

        unless ($command)
        {
            return;
        }

        try
        {
            my $instance = $command->new;
            $instance->settings($self->get_module_settings($command));

            if ($instance->access($event))
            {
                $instance->run($event);
            }
        }
        catch
        {
            _log('sophia', "[MODULE] modules/$command.pm failed to run: $@");
        };

        return;
    }

    method resolve_command ($command)
    {
        return $self->resolve_command_recursive($command, {});
    }

    # this method will prevent infinite looping using $visited
    # as an array to keep track of previously visited aliases
    method resolve_command_recursive ($command, $visited)
    {
        # if this command is already visited, return
        # to prevent infinite looping
        return  if (exists $visited->{$command});

        # add this command to $visited
        $visited->{$command} = 1;

        # if this command is a module command, then return it
        return $command     if (exists $self->modules->{$command});

        # if it is an alias, then we need to resolve it
        # this will recursively attempt to nail down any alias
        # to a module. Allowing one to set an alias that maps
        # to another alias, which is perfectly legit.
        return $self->resolve_command_recursive($self->aliases->{$command}, $visited)
            if (exists $self->aliases->{$command});

        # otherwise, this is not a valid command
        return;
    }

    method get_module_settings ($module)
    {
        # $module is, or if you're reading this, should, be formatted:
        # 1. A::B::C; or
        # 2. A
        #
        # Settings are stored as:
        # 1. A/B/C;
        # 2. A
        # 3. A/B/*
        # 4. A/*
        # etc
        my @parts = split('::', $module);
        my $length = scalar @parts;

        # load settings in order:
        # $module = A::B::C;
        # 1. A/*
        # 2. A/B/* (overrides settings in 1)
        # 3. A/B/C (overrides settings in 2)
        my $index = 1;
        my $level = '';

        my $settings = {};

        # any global settings?
        if (exists $self->settings->{'*'})
        {
            $settings = $self->settings->{'*'};
        }

        PART: for my $part (@parts)
        {
            # generate the A/../.. sequence
            $level .= '/'   if ($index > 1);
            $level .= $part;

            # setting -- hashref
            my $setting;

            # if we're at the end
            # don't look for wildcard matching anymore
            # but rather the $level itself
            if ($index == $length)
            {
                last PART   unless (exists $self->settings->{$level});
                $setting = $self->settings->{$level};
            }

            # if we're not at the end
            # look for wildcard matching settings
            else
            {
                my $wildcard = $level . '/*';

                # if there is no wildcard matching
                # then go to the next iteration
                next PART   unless (exists $self->settings->{$wildcard});
                $setting = $self->settings->{$wildcard};
            }

            $settings = Util::Hash->merge($settings, $setting);
            $index++;
        }

        return $settings;
    }
}
