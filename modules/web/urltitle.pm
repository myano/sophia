use MooseX::Declare;
use Method::Signatures::Modifiers;

class web::urltitle with API::Module
{
    use Constants;
    use Encode qw(decode);
    use HTML::Entities;
    use Util::Curl;
    use utf8;

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

    has 'silent'        => (
        default         => FALSE,
        is              => 'rw',
        isa             => 'Bool',
    );

    method run ($event)
    {
        my @urltitles;
        my $content = $event->content;
        my $count = 1;

        WHILE: while ($content =~ m/\b(https?:\/\/[^ ]+)\b/xsmig)
        {
            my $url = $1;
            my $title = $self->urltitle($url);

            if ($title)
            {
                push @urltitles, $title;
            }
            elsif (!$self->silent)
            {
                push @urltitles, 'Failed to find title.';
            }

            # abide by max_entries
            if ($count++ >= $self->max_entries)
            {
                last WHILE;
            }
        }

        if (scalar @urltitles == 1)
        {
            $event->reply($urltitles[0]);
        }
        else
        {
            $count = 1;
            for my $urltitle (@urltitles)
            {
                $event->reply(sprintf('%d. %s', $count++, $urltitle));
            }
        }
    }

    method on_public ($event)
    {
        $self->silent(TRUE);
        $self->run($event);
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

            $title = decode('UTF-8', $title, Encode::FB_QUIET);

            my $laquo = HTML::Entities::decode('&laquo;');
            my $raquo = HTML::Entities::decode('&raquo;');

            $title = sprintf('%s %s %s', $laquo, $title, $raquo);

            return $title;
        }

        return;
    }
}
