use MooseX::Declare;
use Method::Signatures::Modifiers;

class google::search with API::Module
{
    use HTML::Entities;
    use Util::Curl;

    has 'name'  => (
        default => 'google::search',
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
        my $results = $self->search($event->content);
        return  unless $results;

        for my $result (@$results)
        {
            $event->reply(sprintf('%s - %s', $result->{url}, $result->{title}));
        }
    }

    method search ($query)
    {
        $query =~ s/ /+/g;
        $query =~ s/&/%26/g;

        my $response = Util::Curl->get('http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=' . $query);
        return  unless $response;

        my $max_results = 3;
        if (exists $self->settings->{max_results} && $self->settings->{max_results})
        {
            $max_results = $self->settings->{max_results};
        }

        my @results;
        my $idx = 0;

        RESULT: for (1 .. $max_results)
        {
            $idx = index($response, '"unescapedUrl":"', $idx);
            last RESULT     if ($idx == -1);
            $idx += 16;

            my $url = substr($response, $idx, index($response, '"', $idx) - $idx);
            $url = $self->unescape($url);

            $idx = index($response, '"titleNoFormatting":"', $idx);
            last RESULT     if ($idx == -1);
            $idx += 21;

            my $title = substr($response, $idx, index($response, '"', $idx) - $idx);
            $title = decode_entities($self->unescape($title));

            my %result = (
                url     => $url,
                title   => $title,
            );

            push @results, \%result;
        }

        return \@results;
    }

    method unescape ($str)
    {
        $str =~ s/\\u(.{4})/chr(hex($1))/eg;
        return $str;
    }
}
