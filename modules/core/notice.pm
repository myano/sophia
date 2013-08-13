use MooseX::Declare;
use Method::Signatures::Modifiers;

class core::notice with API::Module
{
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
            $event->sophia->yield(notice => $recipient => $content);
        }
    }
}
