use MooseX::Declare;
use Method::Signatures::Modifiers;

class Util::Curl
{
    use constant USERAGENT => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.116 Safari/537.36';

    use API::Log qw(:ALL);
    use Constants;
    use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
    use WWW::Curl::Easy;

    has 'postheaders'   => (
        default         => sub { [] },
        is              => 'rw',
        isa             => 'ArrayRef',
    );

    method get ($uri)
    {
        return unless $uri =~ /\Ahttps?:\/\/((?:www\.)?[^ \/]+)[^ ]*\z/;

        my @headers = (
            'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Encoding: gzip,deflate,sdch',
            'Accept-Language: en-US,en;q=0.8,zh;q=0.6,zh-CN;q=0.4,zh-TW;q=0.2,fr;q=0.2,fr-FR;q=0.2,ja;q=0.2,es;q=0.2',
            'Connection: keep-alive',
            'DNT: 1',
            'Host: ' . $2,
            'User-Agent: ' . USERAGENT,
        );

        my $curl = WWW::Curl::Easy->new;
        $curl->setopt(CURLOPT_AUTOREFERER, 1);
        $curl->setopt(CURLOPT_CONNECTTIMEOUT, 7);
        $curl->setopt(CURLOPT_COOKIEFILE, $sophia::BASE{ETC} . '/cookies.txt');
        $curl->setopt(CURLOPT_COOKIEJAR, $sophia::BASE{ETC} . '/cookies.txt');
        $curl->setopt(CURLOPT_COOKIESESSION, 1);
        $curl->setopt(CURLOPT_FOLLOWLOCATION, 1);
        $curl->setopt(CURLOPT_HEADER, 0);
        $curl->setopt(CURLOPT_HTTPHEADER, \@headers);
        $curl->setopt(CURLOPT_MAXREDIRS, 2);
        $curl->setopt(CURLOPT_TIMEOUT, 5);
        $curl->setopt(CURLOPT_URL, $uri);
        $curl->setopt(CURLOPT_VERBOSE, TRUE);

        my $response;
        $curl->setopt(CURLOPT_WRITEDATA, \$response);
        
        my $retcode = $curl->perform;
        if ($retcode == 0)
        {
            my $gresponse;
            gunzip \$response => \$gresponse;
            return $gresponse;
        }

        _log('sophia', sprintf('[Util::Curl::get] An error occured. retcode: %s. Error: %s %s', $retcode, $curl->strerror($retcode), $curl->errbuf));

        return;
    }

    method download ($uri, $path, $gpath = '')
    {
        return unless $uri =~ /\Ahttps?:\/\/((?:www\.)?[^ \/]+)[^ ]*\z/;

        my @headers = (
            'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Encoding: gzip,deflate,sdch',
            'Accept-Language: en-US,en;q=0.8,zh;q=0.6,zh-CN;q=0.4,zh-TW;q=0.2,fr;q=0.2,fr-FR;q=0.2,ja;q=0.2,es;q=0.2',
            'Connection: keep-alive',
            'DNT: 1',
            'Host: ' . $2,
            'User-Agent: ' . USERAGENT,
        );

        open(my $fh, '>', $path) or _log('sophia', sprintf('[Util::Curl::download] Unable to open download path: %s', $!)) and return;

        my $curl = WWW::Curl::Easy->new;
        $curl->setopt(CURLOPT_AUTOREFERER, 1);
        $curl->setopt(CURLOPT_CONNECTTIMEOUT, 7);
        $curl->setopt(CURLOPT_COOKIEFILE, $sophia::BASE{ETC} . '/cookies.txt');
        $curl->setopt(CURLOPT_COOKIEJAR, $sophia::BASE{ETC} . '/cookies.txt');
        $curl->setopt(CURLOPT_COOKIESESSION, 1);
        $curl->setopt(CURLOPT_FOLLOWLOCATION, 1);
        $curl->setopt(CURLOPT_HEADER, 0);
        $curl->setopt(CURLOPT_HTTPHEADER, \@headers);
        $curl->setopt(CURLOPT_MAXREDIRS, 2);
        $curl->setopt(CURLOPT_TIMEOUT, 5);
        $curl->setopt(CURLOPT_URL, $uri);
        $curl->setopt(CURLOPT_VERBOSE, TRUE);
        $curl->setopt(CURLOPT_WRITEDATA, $fh);
        
        my $retcode = $curl->perform;
        close $fh;

        if ($retcode == 0)
        {
            if ($gpath)
            {
                gunzip $path => $gpath or _log('sophia', sprintf('[Util::Curl::download] Unable to decompress gzip file: %s', $GunzipError));
            }

            return 1;
        }

        _log('sophia', sprintf('[Util::Curl::download] An error occured. retcode: %s. Error: %s %s', $retcode, $curl->strerror($retcode), $curl->errbuf));

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
