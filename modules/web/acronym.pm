use MooseX::Declare;
use Method::Signatures::Modifiers;

class web::acronym with API::Module
{
    use URI::Escape;
    use Util::Curl;

    has 'name'  => (
        default => 'web::acronym',
        is      => 'ro',
        isa     => 'Str',
    );

    has 'version'   => (
        default     => '1.0',
        is          => 'ro',
        isa         => 'Str',
    );

    has 'max_entries'   => (
        default     => '10',
        is          => 'rw',
        isa         => 'Int',
    );

    method run ($event)
    {
        my $result = $self->acronym($event->content);
        my @acronyms = @$result;

        unless (scalar @acronyms)
        {
            $event->reply('Acronym not found in the database.');
            return;
        }

        $event->reply( join(',', @acronyms) );
    }

    method acronym ($content)
    {
        my $response = Util::Curl->get(sprintf('http://acronyms.thefreedictionary.com/%s', uri_escape($content)));
        return unless $response;

        my @acronyms;
        my $idx = 0;

        LOOP: for (1 .. $self->max_entries)
        {
            $idx = index($response, '<td class=acr>', $idx);
            last FOR    unless $idx > -1;

            $idx = index($response, '<td>', $idx + 1);

            my $acronym = substr($response, $idx + 4, index($response, '</td>', $idx + 1) - $idx - 4);
            $acronym =~ s/<[^>]+>//g;

            push @acronyms, $acronym;

            $idx += 3;
        }

        return \@acronyms;
    }
}
