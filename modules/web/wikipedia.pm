use MooseX::Declare;
use Method::Signatures::Modifiers;

class web::wikipedia with API::Module
{
    use HTML::Entities;
    use URI::Escape;
    use Util::Curl;
    use Util::String;

    has 'name'  => (
        default => 'web::wikipedia',
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
        my $result = $self->wikipedia($event->content);
        return unless $result;

        if ($result->{entry})
        {
            $event->reply($result->{entry});
        }

        if ($result->{url})
        {
            $event->reply('Read more: ' . $result->{url});
        }
    }

    method wikipedia ($search)
    {
        my $response = Util::Curl->get(sprintf('http://en.wikipedia.org/w/api.php?action=opensearch&search=%s&limit=1&namespace=0&format=xml', uri_escape($search)));
        return unless $response;

        my $idx = index($response, '<Description ');
        return unless $idx > -1;

        $idx = index($response, '>', $idx + 1);

        my %wikipedia_entry = (
            entry       => '',
            url         => '',
        );

        my $result = substr($response, $idx + 1, index($response, '</Description>', $idx) - $idx - 1);
        $wikipedia_entry{entry} = Util::String->trim($result);

        $idx = index($response, '<Url ', $idx);
        $idx = index($response, '>', $idx + 1);

        my $url = substr($response, $idx + 1, index($response, '</Url>', $idx) - $idx - 1);
        $wikipedia_entry{url} = $url;

        return \%wikipedia_entry;
    }
}
