use MooseX::Declare;
use Method::Signatures::Modifiers;

class core::notice with API::Module
{
    use Protocol::IRC::Constants;
    use Util::String;

    has 'name'  => (
        default => 'core::notice',
        is      => 'ro',
        isa     => 'Str',
    );

    has 'version'   => (
        default     => '1.0',
        is          => 'ro',
        isa         => 'Str',
    );

    method access ($event)
    {
        return $event->is_sender_operator();
    }

    method run ($event)
    {
        # trigger format
        # --to=recipient  -or-   --to recipient  (required)
        # text
        my $content = $event->content;
        my $recipient;

        if ($content =~ /--to(=| )([^ ]+)/i)
        {
            $recipient = $2;
            $content =~ s/\s*--to(=| )([^ ]+)\s*//i;
        }

        if (defined($recipient))
        {
            my $messages_ref = Util::String->chunk_split($content, IRC_MESSAGE_LENGTH);
            $messages_ref = Util::String->trim_all($messages_ref);

            MESSAGE: for my $message (@$messages_ref)
            {
                next MESSAGE    unless $message;

                $event->sophia->yield(notice => $recipient => $message);
            }
        }
    }
}
