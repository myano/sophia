use MooseX::Declare;
use Method::Signatures::Modifiers;

class core::version with API::Module
{
    has 'name'  => (
        default => 'core::version',
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
        my $commit = $sophia::CONFIGURATIONS{VERSION}->[1] || $sophia::CONFIGURATIONS{VERSION}->[0];
        $event->reply($commit);
    }
}
