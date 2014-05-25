use MooseX::Declare;
use Method::Signatures::Modifiers;

class Protocol::IRC::Manager
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

    has 'operators' => (
        default     => sub { {} },
        is          => 'rw',
        isa         => 'HashRef',
    );

    method add_connection ($server)
    {
        # no uid? do nothing
        return FALSE    unless (exists $server->{uid});

        my $session = Protocol::IRC::Session->new(%$server);
        $session->spawn;

        $self->connections->{ $server->{uid} } = $session;

        return TRUE;
    }

    method find_connection ($uid)
    {
        my $configs = API::Config->get_config($sophia::CONFIGURATIONS{MAIN_CONFIG});

        for my $server (@{$configs->{servers}})
        {
            if ($server->{uid} eq $uid)
            {
                return $server;
            }
        }

        return;
    }

    method initial_startup
    {
        my $configs = API::Config->get_config($sophia::CONFIGURATIONS{MAIN_CONFIG});
        
        if (exists $configs->{operators})
        {
            $self->set_operators($configs->{operators});
        }

        $self->load_connections($configs->{servers});
    }

    method load_connections ($servers)
    {
        for my $server (@$servers)
        {
            $self->add_connection($server);
        }

        return $self;
    }

    method remove_connection ($uid)
    {
        return      unless (exists $self->connections->{$uid});
        
        my $session = $self->connections->{$uid};
        $session->yield(shutdown => 'Shutting down ... ');

        delete $self->connections->{$uid};
    }

    method set_operators ($operators)
    {
        my %opers;

        for my $oper (@$operators)
        {
            while (my ($name, $hash) = each %$oper)
            {
                if (!exists $opers{$name})
                {
                    $opers{$name} = +{};
                }

                $opers{$name}{password} = $hash;
            }
        }

        $self->operators(\%opers);
    }
}
