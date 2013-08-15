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
        my $count = 1;

        WHILE: while ($event->content =~ m/\b(https?:\/\/[^ ]+)\b/xsmig)
        {
            my $url = $1;
            my $title = $self->urltitle($url);

            if ($title)
            {
                push @urltitles, $title;
            }
            else
            {
                push @urltitles, 'Failed to find title.';
            }

            # abide by max_entries
            if ($count++ >= $self->max_entries)
            {
                last WHILE;
            }
        }

        $count = 1;
        for my $urltitle (@urltitles)
        {
            $event->reply(sprintf('%d. %s', $count++, $urltitle));
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
