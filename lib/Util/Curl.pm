use MooseX::Declare;
use Method::Signatures::Modifiers;

class Util::Curl
{
    use API::Log qw(:ALL);
    use WWW::Curl::Easy;
    use XML::LibXML;

    method get ($uri)
    {
        return unless $uri =~ /\Ahttps?:\/\/[^ ]+\z/;

        my $curl = WWW::Curl::Easy->new;
        $curl->setopt(CURLOPT_HEADER, 0);
        $curl->setopt(CURLOPT_FOLLOWLOCATION, 1);
        $curl->setopt(CURLOPT_USERAGENT, 'Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US; rv:1.9.1.6) Gecko/20091201 Firefox/3.5.6 GTB5');
        $curl->setopt(CURLOPT_URL, $uri);

        my $response;
        $curl->setopt(CURLOPT_WRITEDATA, \$response);
        
        my $retcode = $curl->perform;
        if ($retcode == 0)
        {
            return $response;
        }

        _log('sophia', sprintf('[Util::Curl::get] An error occured. retcode: %s. Error: %s %s', $retcode, $curl->strerror($retcode), $curl->errbuf));
        return;
    }

    method post ($uri, $postdata)
    {
        return unless $uri =~ /\Ahttps?:\/\/[^ ]+\z/;
        
        my %postdata = %{$postdata};

        my $data = '';
        $data = sprintf('%s=%s&', $_, $postdata{$_}) for keys %postdata;
        
        my $curl = WWW::Curl::Easy->new;
        $curl->setopt(CURLOPT_HEADER, 0);
        $curl->setopt(CURLOPT_USERAGENT, 'Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US; rv:1.9.1.6) Gecko/20091201 Firefox/3.5.6 GTB5');
        $curl->setopt(CURLOPT_URL, $uri);
        $curl->setopt(CURLOPT_POST, scalar(keys %postdata));
        $curl->setopt(CURLOPT_POSTFIELDS, $data);

        my $response;

        $curl->setopt(CURLOPT_WRITEDATA, \$response);

        my $retcode = $curl->perform;

        if ($retcode == 0)
        {
            return $response;
        }

        _log('sophia', sprintf('[LIBRARY: libcurl::curl_post] An error occured. retcode: %s. Error: %s %s', $retcode, $curl->strerror($retcode), $curl->errbuf));
        return;
    }

    method loadXML ($uri)
    {
        my $result = $self->get($uri);
        return unless $result;

        my $xml = XML::LibXML->new;
        return \$xml->parse_string($result);
    }
}
