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

    method is_sender_operator ()
    {
        my %operators = %{$sophia::instances->operators};
        my $sender    = $self->sender;
        my $hostmask  = $sender;

        my $idx = index $sender, '!';
        if ($idx != -1)
        {
            $hostmask = substr $sender, $idx + 1;
        }

        while (my ($user, $data) = each %operators)
        {
            # has hostmask?
            if (exists $data->{hostmask})
            {
                if ($data->{hostmask} eq $hostmask)
                {
                    return TRUE;
                }
            }
        }

        return FALSE;
    }
}
