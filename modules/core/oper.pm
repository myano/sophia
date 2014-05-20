use MooseX::Declare;
use Method::Signatures::Modifiers;

class core::oper with API::Module
{
    use Constants;

    has 'name'  => (
        default => 'core::name',
        is      => 'ro',
        isa     => 'Str',
    );

    has 'version'   => (
        default     => '1.0',
        is          => 'ro',
        isa         => 'Str',
    );

    # limit access to ONLY private messages
    method access ($event)
    {
        return $event->is_private_message();
    }
    
    method run ($event)
    {
        my @parts = split ' ', $event->content;
        my $pct = scalar @parts;
        my %auth_info;

        my $idx = index $event->sender, '!';

        if ($pct == 1)
        {
            if ($idx != -1)
            {
                my $nick = substr $event->sender, 0, $idx;

                %auth_info = (
                    name        => $nick,
                    password    => $parts[0],
                    hostmask    => substr($event->sender, $idx + 1),
                );
            }
        }
        elsif ($pct == 2)
        {
            %auth_info = (
                name        => $parts[0],
                password    => $parts[1],
                hostmask    => substr($event->sender, $idx + 1),
            );
        }

        if (!%auth_info)
        {
            $event->reply('Parameters: [<user>] <password>');
            return;
        }

        my $authenticated = $self->_authenticate(\%auth_info);
        if ($authenticated->{Success})
        {
            $event->reply('Authenticated. You are now an operator.');
        }
        else
        {
            $event->reply($authenticated->{Message});
        }
    }

    method _authenticate ($auth_hash)
    {
        my %auth_info = %$auth_hash;

        if (!exists $auth_info{name}
            || !exists $auth_info{password})
        {
            return +{
                Success     => FALSE,
                Message     => 'Invalid Credentials',
            };
        }

        my $auth_name = lc $auth_info{name};

        # in opers list?
        my $operators = $sophia::instances->operators;
        while (my ($name, $opts) = each %$operators)
        {
            if (lc $name eq $auth_name)
            {
                my $password = $opts->{password};
                my @parts = split '\$', $password;
                
                if (scalar @parts == 4)
                {
                    my $algorithm = sprintf('$%s$%s$', $parts[1], $parts[2]);
                    my $auth_hash = crypt($auth_info{password}, $algorithm);

                    if ($auth_hash eq $password)
                    {
                        $operators->{$name}->{authenticated} = TRUE;
                        $operators->{$name}->{auth_time}     = time;
                        $operators->{$name}->{hostmask}      = $auth_info{hostmask};

                        return +{
                            Success     => TRUE,
                        };
                    }
                }

                return +{
                    Success     => FALSE,
                    Message     => 'Invalid Password',
                };
            }
        }

        return +{
            Success     => FALSE,
            Message     => 'Permission Denied',
        };
    }
}
