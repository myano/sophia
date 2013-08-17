use MooseX::Declare;
use Method::Signatures::Modifiers;

class contrib::ping with API::Module
{
    has 'name'  => (
        default => 'contrib::ping',
        is      => 'ro',
        isa     => 'Str',
    );

    has 'version'   => (
        default => '1.0',
        is      => 'ro',
        isa     => 'Str',
    );

    method run ($event)
    {
        $event->reply('PONG');
    }
}
