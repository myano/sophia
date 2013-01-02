use MooseX::Declare;
use Method::Signatures::Modifiers;

class Protocol::IRC::Event
{
    use Constants;

    has 'sophia'    => (
        is          => 'ro',
        isa         => 'Protocol::IRC::Session',
        required    => TRUE,
    );
}
