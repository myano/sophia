use MooseX::Declare;
use Method::Signatures::Modifiers;

class core::rehash with API::Module
{
    use API::Log qw(:ALL);
    use Protocol::IRC;

    has 'name'  => (
        default => 'core::rehash',
        is      => 'ro',
        isa     => 'Str',
    );

    has 'version'   => (
        default     => '1.0',
        is          => 'ro',
        isa         => 'Str',
    );

    method run ($event)
    {
        my $uid = $event->sophia->uid;
        my $connection = Protocol::IRC->find_connection($uid);

        unless ($connection)
        {
            $sophia::instances->remove_connection($uid);
            return;
        }

        # these settings will require a restart
        if ($connection->{usessl} != $event->sophia->usessl  ||
            $connection->{port}   != $event->sophia->port    ||
            $connection->{host}   ne $event->sophia->host    ||
            $connection->{username} ne $event->sophia->username  ||
            $connection->{realname} ne $event->sophia->realname)
        {
            $sophia::instances->remove_connection($uid);
            sleep(1);
            $sophia::instances->add_connection($connection);

            return;
        }

        # these settings can just be set on the fly
        $event->sophia->trigger($connection->{trigger});
        $event->sophia->owner_host($connection->{owner_host});
        $event->sophia->owner_name($connection->{owner_nick});

        # remove current usermodes
        $event->sophia->yield(mode => sprintf('%s -%s', $event->sophia->nick, substr($event->sophia->usermode, 1)));

        # add new usermodes
        $event->sophia->yield(mode => sprintf('%s %s', $event->sophia->nick, $connection->{usermode}));

        # this is left for last because nick changes is not guaranteed
        # so if this fails, it would be hard to determine sophia's nick
        $event->sophia->yield(nick => $connection->{nick});
        sleep(1);
        $event->sophia->nick( $event->sophia->session->nick_name() );
    }
}
