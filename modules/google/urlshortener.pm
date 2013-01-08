use MooseX::Declare;
use Method::Signatures::Modifiers;

class google::urlshortener with API::Module
{
    use URI::Escape;
    use Util::Curl;

    has 'name'  => (
        default => 'google::urlshortener',
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
        my $shorturl = $self->shorten($event->content);
        return  unless $shorturl;

        $event->reply($shorturl);
    }

    method shorten ($url)
    {
        # currently, an api_key is not required to use this module
        # but if you have one, it'll be passed along
        my $api_key = '';
        if (exists $self->settings->{api_key} && $self->settings->{api_key})
        {
            $api_key = $self->settings->{api_key};
        }

        my $curl_url = 'https://www.googleapis.com/urlshortener/v1/url';
        if ($api_key)
        {
            $curl_url .= '?key=' . $api_key;
        }

        my $json = '{"longUrl": "' . uri_escape($url) . '"}'; 

        my $curl = Util::Curl->new(
            postheaders     => ['Content-Type: application/json'],
        );

        my $response = $curl->post($curl_url, $json); 
        return  unless $response;

        my $index = index($response, '"id": "');
        return  unless $index;

        $index += 7;
        return substr($response, $index, index($response, '"', $index) - $index);
    }
}
