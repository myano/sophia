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
        default     => '1.0',
        is          => 'ro',
        isa         => 'Str',
    );

    method run ($event)
    {
        my $result = $self->calculate($event->content);
        
        unless ($result && $result->{lhs} && $result->{rhs})
        {
            $event->reply('Unable to compute "' . $event->content . '".');
            return;
        }

        $event->reply( sprintf('%s = %s', $result->{lhs}, $result->{rhs}) );
    }

    method calculate ($expr)
    {
        my $response = Util::Curl->get(sprintf('http://www.google.com/ig/calculator?q=%s', uri_escape($expr)));
        return unless ($response || $response =~ /error:\s*"0?"/);

        my %result = (
            lhs     => '',
            rhs     => '',
        );

        my $idx = index($response, 'lhs: "') + 6;
        $result{lhs} = substr($response, $idx, index($response, '",', $idx) - $idx);

        $idx = index($response, 'rhs: "') + 6;
        $result{rhs} = substr($response, $idx, index($response, '",', $idx) - $idx);

        return \%result;
    }
}
