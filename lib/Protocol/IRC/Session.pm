use MooseX::Declare;
use Method::Signatures::Modifiers;

class Protocol::IRC::Session
{
    use API::Config;
    use API::Log qw(:ALL);
    use API::Module::Handler;
    use Constants;
    use Protocol::IRC;
    use Protocol::IRC::Response;
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

    has 'is_authenticated' => (
        default     => FALSE,
        is          => 'rw',
        isa         => 'Bool',
    );

    has 'is_connected' => (
        default     => FALSE,
        is          => 'rw',
        isa         => 'Bool',
    );

    has 'nick'      => (
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

    has 'usesasl'   => (
        default     => FALSE,
        is          => 'rw',
        isa         => 'Bool',
    );

    has 'usessl'    => (
        default     => FALSE,
        is          => 'rw',
        isa         => 'Bool',
    );


    # private attributes
    has 'session'  => (
        is          => 'rw',
        isa         => 'Protocol::IRC',
    );

    has 'modulehandler' => (
        is          => 'rw',
        isa         => 'API::Module::Handler',
    );

    method spawn
    {
        my $session = Protocol::IRC->spawn(
            Nick        => $self->nick,
            Username    => $self->username,
            Password    => $self->password,
            Ircname     => $self->realname,
            Server      => $self->host,
            Port        => $self->port,
            UseSSL      => $self->usessl,
            UseSASL     => $self->usesasl,
            Flood       => 1,
        ) or error_log('sophia', "Unable to spawn Protocol::IRC: $!\n");

        $self->session($session);

        my $modulehandler = API::Module::Handler->new;
        $self->modulehandler($modulehandler);

        POE::Session->create(
            inline_states => {
                _default            => \&Protocol::IRC::Response::_default,
                _start              => \&Protocol::IRC::Response::_start,
                _stop               => \&Protocol::IRC::Response::_stop,
                cap_end             => \&Protocol::IRC::Response::_cap_end,
                irc_001             => \&Protocol::IRC::Response::_001,
                irc_332             => \&Protocol::IRC::Response::_332,
                irc_903             => \&Protocol::IRC::Response::_903,
                irc_904             => \&Protocol::IRC::Response::_904,
                irc_905             => \&Protocol::IRC::Response::_905,
                irc_906             => \&Protocol::IRC::Response::_906,
                irc_907             => \&Protocol::IRC::Response::_907,
                irc_authenticate    => \&Protocol::IRC::Response::_authenticate,
                irc_cap             => \&Protocol::IRC::Response::_cap,
                irc_connected       => \&Protocol::IRC::Response::_connected,
                irc_disconnected    => \&Protocol::IRC::Response::_disconnected,
                irc_error           => \&Protocol::IRC::Response::_error,
                irc_msg             => \&Protocol::IRC::Response::_privmsg,
                irc_public          => \&Protocol::IRC::Response::_public,
                irc_socketerr       => \&Protocol::IRC::Response::_socketerr,
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

        # some commands do not require args
        $rest = ''      unless (defined($rest));

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

    method process_event_command ($type, $event)
    {
        $self->modulehandler->process_event_command($type, $event);
    }
}
