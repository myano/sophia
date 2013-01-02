use MooseX::Declare;
use Method::Signatures::Modifiers;

role Protocol::IRC::Event
{
    use Constants;

    has 'sophia'    => (
        is          => 'ro',
        isa         => 'Protocol::IRC::Session',
        required    => TRUE,
    );
}
