use MooseX::Declare;
use Method::Signatures::Modifiers;

class API::Module::Handler
{
    use API::Log qw(:ALL);
    use Class::Load qw(:all);
    use Constants;
    use Try::Tiny;
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

    method autoload_aliases
    {
        open my $fh, '<', $sophia::CONFIGURATIONS{ALIAS_DB}
            or _log('sophia', "Unable to open alias database for reading: $!");

        LINE: while (my $line = <$fh>)
        {
            chomp($line);
            next LINE   if (Util::String->is_empty($line));   # skip empty lines

            my ($key, $value) = split(' ', $line);

            $self->aliases->{$key} = $value;
        }

        close $fh;

        return;
    }

    method autoload_modules
    {
        my $modules_config_file = $sophia::CONFIGURATIONS{MODULES_CONFIG} or return;
        return unless -e $modules_config_file;

        open my $fh, '<', $modules_config_file
            or _log('sophia', "Error opening modules config file: $!");

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
        }

        _log('sophia', "[MODULE] modules/$module_path.pm loaded but is_class_loaded returned false.");
        return FALSE;
    }

    method process_command ($event)
    {
        use Data::Dumper;
        my $command = $self->resolve_command($event->command);

        if (!$command)
        {
            return;
        }

        my $i = $command->new;
        $i->run($event);
        return;

        try
        {
            my $instance = $command->new;

            if ($instance->access($event))
            {
                $instance->run($event);
            }
        }
        catch
        {
            _log('sophia', "[MODULE] modules/$command.pm failed to instantiate: $_");
        }

        return;
    }

    method resolve_command ($command)
    {
        # if this command is a module command, then return it
        return $command     if (exists $self->modules->{$command});

        # if it is an alias, then we need to resolve it
        # this will recursively attempt to nail down any alias
        # to a module. Allowing one to set an alias that maps
        # to another alias, which is perfectly legit.
        return $self->resolve_command($self->aliases->{$command})
            if (exists $self->aliases->{$command});

        # otherwise, this is not a valid command
        return;
    }
}
