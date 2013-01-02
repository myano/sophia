use MooseX::Declare;
use Method::Signatures::Modifiers;

class google::calculator with API::Module
{
    use URI::Escape;
    use Util::Curl;

    has 'name'  => (
        default => 'google::calculator',
        is      => 'ro',
        isa     => 'Str',
    );

    has 'version'   => (
        default => '1.0',
        is      => 'ro',
        isa     => 'Str',
    );

    method run ($event)
    {
        my $response = Util::Curl->get(sprintf('http://www.google.com/ig/calculator?q=%s', uri_escape($event->content)));
        return unless ($response || $response =~ /error:\s*"0?"/);

        my $reply = '';
        my $idx = index($response, 'lhs: "') + 6;
        $reply .= substr($response, $idx, index($response, '",', $idx) - $idx);

        $idx = index($response, 'rhs: "') + 6;
        $reply .= sprintf(' = %s', substr($response, $idx, index($response, '",', $idx) - $idx));

        $event->reply($reply);
    }
}
