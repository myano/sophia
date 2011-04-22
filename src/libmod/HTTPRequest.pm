use strict;
use warnings;
use HTTP::Request;
use HTTP::Response;
use LWP::UserAgent;
use URI::Heuristic;
use XML::LibXML;

sub loadXML {
    my $xml = $_[0];
    $xml = ${$xml};
    my $result = get_file_contents(\$xml);
    $result = ${$result};
    return unless $result;
    
    my $objXML = XML::LibXML->new;
    return \$objXML->parse_string($result);
}

sub get_http_response {
    my $uri = $_[0];
    $uri = ${$uri};
    return unless ($uri =~ /^https?:\/\/[^ ]+$/);

    $uri = URI::Heuristic::uf_urlstr($uri);
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;
    $ua->max_redirect(0);
    $ua->agent("Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US; rv:1.9.1.6) Gecko/20091201 Firefox/3.5.6 GTB5");
    my $response = $ua->get($uri);

    return \$response;
}

sub get_file_contents {
    my $response = get_http_response($_[0]);

    return if ($response->is_error());
    return \$response->content;
}

sub get_lns {
    my $uri = $_[0];
    $uri = ${$uri};
    return unless ($uri =~ /^https?:\/\/[^ ]+$/);

    $uri = URI::Heuristic::uf_urlstr($uri);

    my $ua = LWP::UserAgent->new;
    my $req = HTTP::Request->new( POST => 'http://ln-s.net/home/api.jsp' );
    $req->content_type('application/x-www-form-urlencoded');
    $req->content("url=$uri");

    my $response = $ua->request($req);
    return if $response->is_error();

    my $content = $response->content;

    my @parts = split / /, $content;
    return unless $parts[0] eq '200';

    return \$parts[1];
}

1;
