package Protocol::IRC;
use strict;
use warnings;
use POE;
use base qw(POE::Component::IRC);

sub _send_login
{
    my ($kernel, $self, $session) = @_[KERNEL, OBJECT, SESSION];

    if (!defined $self->{usesasl} || !$self->{usesasl})
    {
        $kernel->call($session, 'sl_login', 'CAP REQ :identify-msg');
        $kernel->call($session, 'sl_login', 'CAP REQ :multi-prefix');
        $kernel->call($session, 'sl_login', 'CAP LS');
        $kernel->call($session, 'sl_login', 'CAP END');

        if (defined $self->{password})
        {
            $kernel->call($session => sl_login => 'PASS ' . $self->{password});
        }

        $kernel->call($session => sl_login => 'NICK ' . $self->{nick});
        $kernel->call(
            $session,
            'sl_login',
            'USER ' .
            join(' ', $self->{username},
                (defined $self->{bitmode} ? $self->{bitmode} : 8),
                '*',
                ':' . $self->{ircname}
            ),
        );
    }

    $kernel->delay(sl_delayed => 0);

    return;
}

1;
