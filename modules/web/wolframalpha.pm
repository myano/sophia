use MooseX::Declare;
use Method::Signatures::Modifiers;

class web::wolframalpha with API::Module
{
    use Data::Dumper;
    use URI::Escape;
    use Util::Curl;
    use XML::LibXML;

    has 'name'  => (
        default => 'web::wolframalpha',
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
        my $result = $self->wolframalpha($event->content);
        return unless $result;

        $event->reply($result);
    }

    method wolframalpha ($query)
    {
        # requires an API key!
        unless (exists $self->settings->{api_key} && $self->settings->{api_key})
        {
            return;
        }

        my @pods = (
            'Input',
            'Solution',
            'Value',
        );

        my $url = 'https://api.wolframalpha.com/v2/query?appid=%s&input=%s&';

        for my $pod (@pods)
        {
            $url .= 'includepodid=' . $pod . '&';
        }

        $url = sprintf($url, $self->settings->{api_key}, uri_escape($query));

        my $response = Util::Curl->get($url);
        return unless $response;

        my $xml = XML::LibXML->load_xml(
            string      => $response
        );
        my $xpc = XML::LibXML::XPathContext->new($xml);

        # solutions
        my $solutions = $self->_solutions($xpc);
        if ($solutions ne '')
        {
            return $solutions;
        }

        # values
        my $values = $self->_values($xpc);
        if ($values ne '')
        {
            return $values;
        }

        return;
    }

    method _solutions ($xpc)
    {
        my $response = '';

        my @solutions = $xpc->findnodes('//pod[@id="Solution"]/subpod');
        foreach my $solution (@solutions)
        {
            my $text = $solution->findnodes('./plaintext[1]');
            $response .= $text->to_literal . ', ';
        }

        $response =~ s/, \Z//;

        return $response;
    }

    method _values ($xpc)
    {
        my $response = '';

        my @values = $xpc->findnodes('//pod[@id="Value"]/subpod');
        foreach my $value (@values)
        {
            my $text = $value->findnodes('./plaintext[1]');
            $response .= $text->to_literal . ', ';
        }

        $response =~ s/, \Z//;

        return $response;
    }
}
