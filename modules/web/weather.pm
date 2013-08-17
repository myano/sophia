use MooseX::Declare;
use Method::Signatures::Modifiers;

class web::weather with API::Module
{
    use URI::Escape;
    use Util::String;
    use Util::XML;

    has 'name'  => (
        default => 'web::weather',
        is      => 'ro',
        isa     => 'Str',
    );

    has 'version'  => (
        default     => '1.0',
        is          => 'ro',
        isa         => 'Str',
    );

    method run ($event)
    {
        my $content = Util::String->trim($event->content);
        my @dataset;

        my $results = $self->weather($content);
        for my $result (@$results)
        {
            push @dataset, $result->[0]->to_literal;
        }

        $event->reply( sprintf('%s (%s)  --  %s, %s.  Humidity: %s.  Wind: %s, %s degrees at %s mph.  Dewpoint: %s.  Air pressure: %s.  Visibility: %s miles.', @dataset) );
    }

    method weather ($location)
    {
        my $xml = Util::XML->new;
        $xml->parse_by_url('http://api.wunderground.com/auto/wui/geo/WXCurrentObXML/index.xml?query=' . uri_escape($location));
        return unless $xml;

        my @nodes = (
            '//display_location/full',
            '//station_id',
            '//weather',
            '//temperature_string',
            '//relative_humidity',
            '//wind_dir',
            '//wind_degrees',
            '//wind_mph',
            '//dewpoint_string',
            '//pressure_string',
            '//visibility_mi',
        );

        return $xml->get_nodes(\@nodes);
    }
}
