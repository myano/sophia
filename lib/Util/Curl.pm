use MooseX::Declare;
use Method::Signatures::Modifiers;

class Util::Curl
{
    use API::Log qw(:ALL);
    use Constants;
    use WWW::Curl::Easy;

    has 'postheaders'   => (
        default         => sub { [] },
        is              => 'rw',
        isa             => 'ArrayRef',
    );

    method get ($uri)
    {
        return unless $uri =~ /\Ahttps?:\/\/[^ ]+\z/;

        my $curl = WWW::Curl::Easy->new;
        $curl->setopt(CURLOPT_CONNECTTIMEOUT, 7);
        $curl->setopt(CURLOPT_COOKIEFILE, 'cookie.txt');
        $curl->setopt(CURLOPT_COOKIEJAR,  'cookie.txt');
        $curl->setopt(CURLOPT_COOKIESESSION, 1);
        $curl->setopt(CURLOPT_FOLLOWLOCATION, 1);
        $curl->setopt(CURLOPT_HEADER, 0);
        $curl->setopt(CURLOPT_TIMEOUT, 5);
        $curl->setopt(CURLOPT_URL, $uri);
        $curl->setopt(CURLOPT_USERAGENT, '8.35.200.39 Mozilla/5.0 AppEngine-Google');
        $curl->setopt(CURLOPT_VERBOSE, TRUE);

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

        my $data = '';

        # postdata can be an array or hash or simple string
        if (ref $postdata eq 'HASH')
        {
            while (my ($key, $value) = each %$postdata)
            {
                $data .= sprintf('%s=%s&', $key, $value);
            }

            $data =~ s/&\z//;
        }
        elsif (ref $postdata eq 'ARRAY')
        {
            for my $value (@$postdata)
            {
                $data .= $value . '&';
            }

            $data =~ s/&\z//;
        }
        else
        {
            $data = $postdata;
        }
        
        my $curl = WWW::Curl::Easy->new;
        $curl->setopt(CURLOPT_USERAGENT, 'Mozilla/5.0 (X11; Linux x86_64; rv:22.0) Gecko/20100101 Firefox/22.0');
        $curl->setopt(CURLOPT_URL, $uri);

        if (ref $postdata eq 'HASH')
        {
            $curl->setopt(CURLOPT_POST, scalar(keys %$postdata));
        }
        else
        {
            $curl->setopt(CURLOPT_POST, TRUE);
        }

        if (scalar @{$self->postheaders})
        {
            $curl->setopt(CURLOPT_HEADER, TRUE);
            $curl->setopt(CURLOPT_HTTPHEADER, $self->postheaders);
        }
        else
        {
            $curl->setopt(CURLOPT_HEADER, FALSE);
        }

        $curl->setopt(CURLOPT_CONNECTTIMEOUT, 7);
        $curl->setopt(CURLOPT_TIMEOUT, 5);
        $curl->setopt(CURLOPT_POSTFIELDS, $data);
        $curl->setopt(CURLOPT_VERBOSE, TRUE);

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
}
