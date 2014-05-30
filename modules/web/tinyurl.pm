use MooseX::Declare;
use Method::Signatures::Modifiers;

class web::tinyurl with API::Module
{
    use Util::Curl;

    has 'name'  => (
        default => 'web::tinyurl',
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
        return unless $shorturl;

        $event->reply($shorturl);
    }

    method shorten ($url)
    {
        my $tinyurl = 'http://tinyurl.com/api-create.php?url=' . $url;

        my $curl_data = Util::Curl->get($tinyurl);
        my $response = $curl_data->{content};

        return $response;
    }
}
