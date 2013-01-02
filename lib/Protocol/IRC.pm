use MooseX::Declare;
use Method::Signatures::Modifiers;

class Protocol::IRC
{
    use API::Config;
    use Constants;
    use Protocol::IRC::Session;

    # list of connections by uid
    # maps: uid => Protocol::IRC::Session
    has 'connections'   => (
        default     => sub { {} },
        is          => 'rw',
        isa         => 'HashRef',
    );

    method add_connection ($config)
    {
        # no uid? do nothing
        return FALSE    unless (exists $config->{uid});

        my $session = Protocol::IRC::Session->new(%{$config});
        $session->spawn;

        $self->connections->{ $config->{uid} } = $session;

        return TRUE;
    }

    method remove_connection ($uid)
    {
        return      unless (exists $self->connections->{$uid});
        
        my $session = $self->connections->{$uid};
        $session->yield(quit => 'Shutting down ... ');

        delete $self->connections->{$uid};
    }

    method autoload_connections
    {
        my $configs = Protocol::IRC::Session->autoload_main_config;

        for my $config (@$configs)
        {
            $self->add_connection($config);
        }

        return;
    }
}
