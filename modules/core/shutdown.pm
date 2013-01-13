use MooseX::Declare;
use Method::Signatures::Modifiers;

class core::shutdown with API::Module
{
    use API::Log qw(:ALL);

    has 'name'  => (
        default => 'core::shutdown',
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
        _log('sophia', sprintf('Shutting down as requested by %s.', $event->sender));
        $event->sophia->yield(quit => 'Shutting down ... ');
    }
}
