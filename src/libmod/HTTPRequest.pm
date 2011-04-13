use strict;
use warnings;
use HTTP::Request;
use HTTP::Response;
use LWP::UserAgent;
use URI::Heuristic;
use XML::LibXML;

sub loadXML {
    my $xml = shift;
    my $result = get_file_contents($xml);
    return unless $result;
    
    my $objXML = XML::LibXML->new;
    return $objXML->parse_string($result);
}

sub get_file_contents {
    my $url = shift;
    return unless ($url =~ m/^http:\/\/[^ ]+$/);

    $url = URI::Heuristic::uf_urlstr($url);
    my $ua = LWP::UserAgent->new();
    $ua->agent("Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US; rv:1.9.1.6) Gecko/20091201 Firefox/3.5.6 GTB5");

    my $req = HTTP::Request->new( GET => $url );
    my $response = $ua->request($req);

    return if ($response->is_error());
    return $response->content;
}

1;
