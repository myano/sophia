use MooseX::Declare;
use Method::Signatures::Modifiers;

class Protocol::IRC::Session
{
    use API::Config;
    use API::Log qw(:ALL);
    use API::Module::Handler;
    use Constants;
    use POE qw(Component::IRC);
    use Protocol::IRC::Response;
    use Try::Tiny;
    use Util::String;

    has 'channels'  => (
        default     => sub { {} },
        is          => 'rw',
        isa         => 'HashRef',
    );

    has 'channel_topics' => (
        default     => sub { {} },
        is          => 'rw',
        isa         => 'HashRef',
    );

    has 'host'      => (
        default     => '',
        is          => 'rw',
        isa         => 'Str',
    );

    has 'nick'      => (
        default     => '',
        is          => 'rw',
        isa         => 'Str',
    );

    has 'owner_host' => (
        default     => '',
        is          => 'rw',
        isa         => 'Str',
    );

    has 'owner_name' => (
        default     => '',
        is          => 'rw',
        isa         => 'Str',
    );

    has 'password'  => (
        default     => '',
        is          => 'rw',
        isa         => 'Str',
    );

    has 'port'      => (
        default     => 0,
        is          => 'rw',
        isa         => 'Int',
    );

    has 'realname'  => (
        default     => '',
        is          => 'rw',
        isa         => 'Str',
    );

    has 'trigger'   => (
        default     => '!',
        is          => 'rw',
        isa         => 'Str',
    );

    has 'uid'       => (
        default     => '',
        is          => 'ro',
        isa         => 'Str',
    );

    has 'usermode'  => (
        default     => '',
        is          => 'rw',
        isa         => 'Str',
    );

    has 'username'  => (
        default     => '',
        is          => 'rw',
        isa         => 'Str',
    );

    has 'usessl'    => (
        default     => FALSE,
        is          => 'rw',
        isa         => 'Bool',
    );


    # private attributes
    has 'session'  => (
        is          => 'rw',
        isa         => 'POE::Component::IRC',
    );

    has 'modulehandler' => (
        is          => 'rw',
        isa         => 'API::Module::Handler',
    );

    method spawn
    {
        my $session = POE::Component::IRC->spawn(
            Nick        => $self->nick,
            Username    => $self->username,
            Password    => $self->password,
            Ircname     => $self->realname,
            Server      => $self->host,
            Port        => $self->port,
            UseSSL      => $self->usessl,
        ) or error_log('sophia', "Unable to spawn POE::Component::IRC: $!\n");

        $self->session($session);

        my $modulehandler = API::Module::Handler->new;
        $modulehandler->autoload_aliases;
        $self->modulehandler($modulehandler);

        POE::Session->create(
            inline_states => {
                _default            => \&Protocol::IRC::Response::_default,
                _start              => \&Protocol::IRC::Response::_start,
                _stop               => \&Protocol::IRC::Response::_stop,
                irc_001             => \&Protocol::IRC::Response::_001,
                irc_332             => \&Protocol::IRC::Response::_332,
                irc_disconnected    => \&Protocol::IRC::Response::_disconnected,
                irc_error           => \&Protocol::IRC::Response::_error,
                irc_public          => \&Protocol::IRC::Response::_public,
                irc_shutdown        => \&Protocol::IRC::Response::_shutdown,
                irc_topic           => \&Protocol::IRC::Response::_topic,
                sig_int             => \&Protocol::IRC::Response::_sigint,
            },
            heap        => {
                sophia              => $self,
            },
        );

        return $self;
    }

    method yield (@args)
    {
        $self->session->yield(@args);
    }


    method autoload_main_config
    {
        my %global;
        my $yaml = API::Config->parse_yaml_config($sophia::CONFIGURATIONS{MAIN_CONFIG});

        my @configs;

        for my $block (@$yaml)
        {
            if (exists $block->{global})
            {
                while (my ($key, $value) = each %{$block->{global}})
                {
                    $global{$key} = $value;
                }
            }
            elsif (exists $block->{server})
            {
                my %config = %global;

                while (my ($key, $value) = each %{$block->{server}})
                {
                    $config{$key} = $value;
                }

                # channels is supposed to be a hash, but YAML processes it as an array
                if (exists $config{channels})
                {
                    my %channels = map { $_ => 1 } @{$config{channels}};
                    $config{channels} = \%channels;
                }

                # ports starting with + indicates ssl
                if (exists $config{port})
                {
                    if (index($config{port}, '+') == 0)
                    {
                        $config{port}   = substr $config{port}, 1;
                        $config{usessl} = TRUE;
                    }
                }

                push @configs, \%config;
            }
        }

        return \@configs;
    }

    method save_main_config
    {
    }

    # takes in a Protocol::IRC::Event::Public
    method process_input ($event)
    {
        # valid command formats:
        # 1. nick[delimiter] module_trigger args
        # 2. [trigger]module_trigger args
        my $message = $event->message;

        # Case 1:
        # Turn case 1 into a Case 2 if possible.
        # - Remove the nick
        # - Add the command trigger
        my $nick = $self->nick;
        if ($message =~ /\A\Q$nick\E[:, ](.*)\z/)
        {
            my $command = Util::String->trim($1);
            $message = $self->trigger . $command . ' ';
        }

        # Case 2:
        my ($command, $rest) = split(' ', $message, 2);

        my $trigger = $self->trigger;
        if ($command !~ /\A\Q$trigger\E[^ :]+(::[^:]+)*\z/)
        {
            return;
        }

        $command =~ s/\A\Q$trigger\E//;

        $rest = Util::String->trim($rest);

        $event->command($command);
        $event->content($rest);

        $self->modulehandler->process_command($event);
    }
}