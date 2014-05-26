use MooseX::Declare;
use Method::Signatures::Modifiers;

class Util::XML
{
    use Util::Curl;
    use XML::LibXML;

    has 'document'  => (
        is          => 'rw',
        isa         => 'XML::LibXML::Document',
    );

    method parse_by_string ($string)
    {
        return unless $string;

        my $xml = XML::LibXML->new;
        my $document = $xml->parse_string($string);
        $self->document($document);
    }

    method parse_by_url ($url)
    {
        my $result = Util::Curl->get($url);
        $self->parse_by_string($result);
    }

    method get_nodes ($nodes)
    {
        my @results;

        FOR: for my $node (@$nodes)
        {
            my $result = $self->document->findnodes($node);

            if (scalar @$result)
            {
                push @results, $result;
            }
            else
            {
                push @results, '';
            }
        }

        return \@results;
    }
}
