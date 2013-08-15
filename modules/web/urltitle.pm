use MooseX::Declare;
use Method::Signatures::Modifiers;

class web::urltitle with API::Module with API::Module::Event::Public
{
    use HTML::Entities;
    use Util::Curl;

    has 'name'  => (
        default => 'web::urltitle',
        is      => 'ro',
        isa     => 'Str',
    );

    has 'version'   => (
        default     => '1.0',
        is          => 'ro',
        isa         => 'Str',
    );

    has 'max_entries'   => (
        default         => 3,
        is              => 'rw',
        isa             => 'Int',
    );

    method run ($event)
    {
        my @urltitles;
        my $index = 1;

        while ($event->content =~ /\b(https?:\/\/[^ ]+)\b/xsmig)
        {
            my $url = $1;
            my $title = $self->urltitle($url);

            if ($title)
            {
                $event->reply(sprintf('%d. %s', $index++, $title));
            }
            else
            {
                $event->reply(sprintf('%d. Failed to find title.', $index++));
            }
        }
    }

    method urltitle ($url)
    {
        my $response = Util::Curl->get($url);
        return unless $response;

        if ($response =~ m#<title[^>]*>(.+?)</title>#xsmi)
        {
            my $title = $1;
            $title =~ s/\r\n|\n//g;
            $title =~ s/^\s+//g;
            $title =~ s/\s{2,}/ /g;

            $title = '&laquo; ' . $title . ' &raquo;';
            $title = HTML::Entities::decode($title);

            return $title;
        }

        return;
    }
}
