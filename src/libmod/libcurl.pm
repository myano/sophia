use strict;
use warnings;
use WWW::Curl::Easy;
use XML::LibXML;

sub loadXML {
    my $uri = $_[0];
    my $result = curl_get($uri);
    return unless $result;

    my $objXML = XML::LibXML->new;
    return \$objXML->parse_string($result);
}

sub curl_get {
    my $uri = $_[0];
    return unless ($uri =~ /^https?:\/\/[^ ]+$/);

    my $curl = WWW::Curl::Easy->new;
    $curl->setopt(CURLOPT_HEADER, 0);
    $curl->setopt(CURLOPT_FOLLOWLOCATION, 1);
    $curl->setopt(CURLOPT_USERAGENT, 'Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US; rv:1.9.1.6) Gecko/20091201 Firefox/3.5.6 GTB5');
    $curl->setopt(CURLOPT_URL, $uri);

    my $response;

    $curl->setopt(CURLOPT_WRITEDATA, \$response);
    
    my $retcode = $curl->perform;
    if ($retcode == 0) {
        return $response;
    }

    sophia_log('sophia', sprintf('[LIBRARY: libcurl::curl_get] An error occured. retcode: %s. Error: %s %s', $retcode, $curl->strerror($retcode), $curl->errbuf));
    return;
}

sub curl_post {
    my ($uri, $postdata) = @_;
    return unless ($uri =~ /^https?:\/\/[^ ]+$/);
    
    my %postdata = %{$postdata};

    my $data = '';
    $data = sprintf('%s=%s&', $_, $postdata{$_}) for keys %postdata;
    
    my $curl = WWW::Curl::Easy->new;
    $curl->setopt(CURLOPT_HEADER, 0);
    $curl->setopt(CURLOPT_USERAGENT, 'Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US; rv:1.9.1.6) Gecko/20091201 Firefox/3.5.6 GTB5');
    $curl->setopt(CURLOPT_URL, $uri);
    $curl->setopt(CURLOPT_POST, scalar(keys %postdata));
    $curl->setopt(CURLOPT_POSTFIELDS, $data);

    my $response = '';
    open my $file, '>', \$response;

    $curl->setopt(CURLOPT_WRITEDATA, \$file);

    my $retcode = $curl->perform;

    if ($retcode == 0) {
        return $response;
    }

    sophia_log('sophia', sprintf('[LIBRARY: libcurl::curl_post] An error occured. retcode: %s. Error: %s %s', $retcode, $curl->strerror($retcode), $curl->errbuf));
    return;
}

1;
