use MooseX::Declare;
use Method::Signatures::Modifiers;

class google::translate with API::Module
{
    use HTML::Entities;
    use URI::Escape;
    use Util::Curl;
    use Util::String;

    has 'name'  => (
        default => 'google::translate',
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
        # the trigger for google::translate module is a bit different
        # than the usual inputs.
        #
        # it allows the options:
        # --source=lang  -or-   --source lang (optional)
        # --target=lang  -or-   --target lang (required)
        # text (required, no tag)
        my $query = {};
        my $content = $event->content;

        if ($content =~ /--from(=| )([^ ]+)/i)
        {
            $query->{source} = $2;
            $content =~ s/\s*--from(=| )([^ ]+)\s*//i;
        }

        if ($content =~ /--to(=| )([^ ]+)/i)
        {
            $query->{target} = $2;
            $content =~ s/\s*--to(=| )([^ ]+)\s*//i;
        }

        $content = Util::String->trim($content);
        $query->{text} = $content;

        # query must have target and text to continue
        unless ($query->{target} && $query->{text})
        {
            return;
        }

        my $result = $self->translate($query);
        return  unless $result;

        my $response = $result->{translatedText};
        if (exists $result->{detectedSourceLanguage})
        {
            $response = sprintf('(%s -> %s): %s', $result->{detectedSourceLanguage}, $query->{target}, $response);
        }

        $event->reply($response);
    }

    # query must be a hashref with the following values:
    # source - source language (optional)
    # target - target language (required)
    # text   - text to translate (required)
    method translate ($query)
    {
        # no api key? no go
        unless (exists $self->settings->{api_key} && $self->settings->{api_key})
        {
            return;
        }
        
        # no target language or text? no go
        unless (exists $query->{target} && $query->{target} &&
                exists $query->{text} && $query->{text})
        {
            return;
        }

        my $request_url = sprintf('https://www.googleapis.com/language/translate/v2?key=%s&target=%s&q=%s', $self->settings->{api_key}, uri_escape($query->{target}), uri_escape($query->{text}));

        if (exists $query->{source} && $query->{source})
        {
            $request_url .= '&source=' . uri_escape($query->{source});
        }

        my $response = Util::Curl->get($request_url);
        return  unless $response;

        my $idx = index($response, '"translatedText": "', 0);
        return  if ($idx == -1);

        $idx += 19;
        my $translation = substr($response, $idx, index($response, '"', $idx) - $idx);

        # if source is not provided, then add in the auto-detected source language
        my $source = '';
        unless (exists $query->{source} && $query->{source})
        {
            $idx = index($response, '"detectedSourceLanguage": "', $idx);
            
            if ($idx > -1)
            {
                $idx += 27;
                $source = substr($response, $idx, index($response, '"', $idx) - $idx);
            }
        }

        my %data = (
            translatedText  => HTML::Entities::decode($translation),
        );

        if ($source)
        {
            $data{detectedSourceLanguage} = $source;
        }

        return \%data;
    }
}
