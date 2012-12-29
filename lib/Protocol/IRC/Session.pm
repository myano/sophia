use MooseX::Declare;
use Method::Signatures::Modifiers;

class Protocol::IRC::Session
{
    use Constants;
    use POE qw(Component::IRC);
    use Protocol::IRC;

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


    # private instance
    has 'session'  => (
        is          => 'rw',
        isa         => 'POE::Component::IRC',
    );

    method spawn
    {
        my $session = POE::Component::IRC->spawn(
            Nick        => $self->nick(),
            Username    => $self->username(),
            Password    => $self->password(),
            Ircname     => $self->realname(),
            Server      => $self->host(),
            Port        => $self->port(),
            UseSSL      => $self->usessl(),
        ) or error_log('sophia', "Unable to spawn POE::Component::IRC: $!\n");

        $self->session($session);

        POE::Session->create(
            inline_states => {
                _default            => \&Protocol::IRC::_default,
                _start              => \&Protocol::IRC::_start,
                _stop               => \&Protocol::IRC::_stop,
                irc_001             => \&Protocol::IRC::_001,
                irc_332             => \&Protocol::IRC::_332,
                irc_disconnected    => \&Protocol::IRC::_disconnected,
                irc_error           => \&Protocol::IRC::_error,
                irc_shutdown        => \&Protocol::IRC::_shutdown,
                irc_topic           => \&Protocol::IRC::_topic,
                sig_int             => \&Protocol::IRC::_sigint,
            },
            heap        => {
                sophia              => $self
            },
        );

        return $self;
    }

    method yield (@args)
    {
        my $session = $self->session();
        $session->yield(@args);
    }
}
