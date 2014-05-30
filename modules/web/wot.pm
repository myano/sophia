use MooseX::Declare;
use Method::Signatures::Modifiers;

class web::wot with API::Module
{
    use POSIX;
    use Util::Curl;

    has 'name'  => (
        default => 'web::wot',
        is      => 'ro',
        isa     => 'Str',
    );

    has 'version'   => (
        default     => '1.0',
        is          => 'ro',
        isa         => 'Str',
    );

    has 'max_entries'   => (
        default         => 3,
        is              => 'rw',
        isa             => 'Int',
    );

    method run ($event)
    {
        my @wot;
        my $content = $event->content;
        my $count = 1;

        WHILE: while ($content =~ m/\b(https?:\/\/[^ ]+)\b/xsmig)
        {
            my $url = $1;
            my $wot = $self->wot($url);

            push @wot, $wot;

            # abide by max_entries
            if ($count++ >= $self->max_entries)
            {
                last WHILE;
            }
        }

        $count = 1;
        for my $wot (@wot)
        {
            $event->reply(sprintf('%d. Reputation: %s   Confidence: %s', $count++, $wot->{reputation}, $wot->{confidence}));
        }
    }

    method wot ($url)
    {
        my $curl_data = Util::Curl->get('http://api.mywot.com/0.4/public_query2?url=' . $url);
        my $response = $curl_data->{content};
        return unless $response;

        my $count = 0;
        my %wot = (
            confidence          => 0,
            reputation          => 0,
        );

        # sum up all confidence & reputation
        while ($response =~ /<application name="\d+" r="(\d+)" c="(\d+)"\/>/g)
        {
            $wot{confidence} += $1;
            $wot{reputation} += $2;
            ++$count;
        }

        # calculate averages
        $wot{confidence} /= $count;
        $wot{reputation} /= $count;

        $wot{confidence} = floor($wot{confidence});
        $wot{reputation} = floor($wot{reputation});


        # store as percentage
        $wot{confidence} = $wot{confidence} . '/100';
        $wot{reputation} = $wot{reputation} . '/100';

        return \%wot;
    }
}
