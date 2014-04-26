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

    method is_private_message ()
    {
        return $self->DOES('Protocol::IRC::Event::PrivateMessage');
    }

    method is_public_message ()
    {
        return $self->DOES('Protocol::IRC::Event::Public');
    }
}
