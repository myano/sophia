use MooseX::Declare;
use Method::Signatures::Modifiers;

class core::restart with API::Module
{
    use API::Log qw(:ALL);
    use Protocol::IRC;

    has 'name'  => (
        default => 'core::restart',
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

        if ($connection)
        {
            _log('sophia', sprintf('Restarting as requested by %s.', $event->sender));
            $sophia::instances->remove_connection($uid);
            sleep(1);
            $sophia::instances->add_connection($connection);
        }
        else
        {
            _log('sophia', sprintf('Unable to find UID connection. Shutting down instead as requested by %s.', $event->sender));
            $sophia::instances->remove_connection($uid);
        }
    }
}
