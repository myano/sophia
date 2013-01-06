use MooseX::Declare;
use Method::Signatures::Modifiers;

class Protocol::IRC::Event::Public with Protocol::IRC::Event
{
    use Constants;
    use Protocol::IRC::Constants;
    use Util::String;

    # hostmask of the user who
    # sent the message
    has 'sender'        => (
        is              => 'ro',
        isa             => 'Str',
        required        => TRUE,
    );

    # ArrayRef of channels
    # that the message was sent to
    has 'recipients'    => (
        is              => 'ro',
        isa             => 'ArrayRef',
        required        => TRUE,
    );

    # message text
    # the original content sent by sender
    # unmodified in any way, shape or form
    has 'message'       => (
        is              => 'ro',
        isa             => 'Str',
        required        => TRUE,
    );

    # determins if NickServ authentication
    # is used.
    has 'hasNickServAuth'  => (
        default         => FALSE,
        is              => 'rw',
        isa             => 'Bool',
        required        => FALSE,
    );

    # determins if sender is identified
    # to NickServ and IRC services
    has 'isNickSerAuth' => (
        default         => FALSE,
        is              => 'rw',
        isa             => 'Bool',
        required        => FALSE,
    );


    # command trigger parsed from message
    # this is generally not very useful
    # however, it is here in case anything
    # wants to know the command.
    has 'command'       => (
        is              => 'rw',
        isa             => 'Str',
        required        => FALSE,
    );

    # content of the message with command removed
    # this is more useful than message when used
    # in modules so the modules do not have to worry
    # about removing the command trigger
    has 'content'       => (
        is              => 'rw',
        isa             => 'Str',
        required        => FALSE,
    );


    method reply ($string)
    {
        $string = Util::String->trim($string);
        return unless $string;

        my $sophia = $self->sophia;

        my $messages_ref = Util::String->chunk_split($string, IRC_MESSAGE_LENGTH);
        $messages_ref = Util::String->trim_all($messages_ref);
        my @messages = @$messages_ref;

        RECIPIENT: for my $recipient (@{$self->recipients})
        {
            MESSAGE: for my $message (@messages)
            {
                unless ($message)
                {
                    next MESSAGE;
                }

                $sophia->yield(privmsg => $recipient => $message);
            }
        }
    }
}
