use MooseX::Declare;
use Method::Signatures::Modifiers;

class Protocol::IRC::Event::PrivateMessage extends Protocol::IRC::Event::Public
{
    use Protocol::IRC::Constants;
    use Util::String;

    # NOTE: whereas recipients for a Public event is an ArrayRef
    # of channel names, the recipients for a PrivateMessage event
    # will be an ArrayRef of nick(s) who private messaged sophia
    #
    # Outside of that, a PrivateMessage is the exact same thing as
    # a Public message.


    # Since the recipient is sophia, we cannot use the Public's reply method.
    # We instead want to send the response back to the sender.
    method reply ($string)
    {
        $string = Util::String->trim($string);
        return  unless $string;

        my $messages_ref = Util::String->chunk_split($string, IRC_MESSAGE_LENGTH);
        $messages_ref = Util::String->trim_all($messages_ref);
        my @messages = @$messages_ref;

        my $recipient = substr($self->sender, 0, index($self->sender, '!'));

        my $sophia = $self->sophia;

        MESSAGE: for my $message (@messages)
        {
            next MESSAGE    unless $message;

            $sophia->yield(privmsg => $recipient => $message);
        }
    }
}
