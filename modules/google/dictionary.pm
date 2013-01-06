use MooseX::Declare;
use Method::Signatures::Modifiers;

class google::dictionary with API::Module
{
    use HTML::Entities;
    use Protocol::IRC::Constants;
    use Util::Curl;

    has 'name'  => (
        default => 'google::dictionary',
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
        isa              => 'Int',
    );

    method run ($event)
    {
        my $results = $self->define($event->content);

        unless ($results)
        {
            $event->reply('No definition available for term "' . $event->content . '".');
            return;
        }

        my $term = $results->{term};
        my $definitions = $results->{definitions};

        for my $result (@$definitions)
        {
            $event->reply( sprintf('%1$s%2$s:%1$s %3$s', IRC_TEXT_FORMAT_BOLD, $term, $result) );
        }
    }

    method define ($expr)
    {
        $expr =~ s/ /+/g;
        $expr =~ s/&/%26/g;

        my $response = Util::Curl->get(sprintf('http://www.google.com/dictionary/json?callback=dict_api.callbacks.id100&sl=en&tl=en&restrict=pr%sde&client=te&q=%s', '%2C', $expr));
        return unless $response;

        my @results;

        my $idx = index($response, '"query":"');
        unless ($idx > -1)
        {
            return;
        }
        $idx += 9;

        my $term = substr($response, $idx, index($response, '"', $idx) - $idx);

        $idx = 0;
        ENTRY: for (1 .. $self->max_entries)
        {
            $idx = index($response, '"type":"meaning"', $idx);
            last ENTRY unless $idx > -1;

            $idx = index($response, '"text":"', $idx + 1);
            last ENTRY unless $idx > -1;

            $idx += 8;

            my $entry = substr($response, $idx, index($response, '"', $idx) - $idx);
            $entry = $self->escape($entry);
            $entry =~ s/\[\d+\]//g;

            push @results, decode_entities($entry);
        }

        my %definitions = (
            definitions => \@results,
            term        => $term,
        );

        return \%definitions;
    }

    method escape ($str)
    {
        $str =~ s/\\x3c/</g;
        $str =~ s/\\x3e/>/g;
        $str =~ s/<[^>]+>//g;
        $str =~ s/\\x(\d{2})/chr(hex($!))/eg;
        
        return $str;
    }
}
