use strict;
use warnings;

sophia_module_add('web.weather', '1.0', \&init_web_weather, \&deinit_web_weather);

sub init_web_weather {
    sophia_command_add('web.weather', \&web_weather, 'Gets weather from api.wunderground.com', '');

    return 1;
}

sub deinit_web_weather {
    delete_sub 'init_web_weather';
    delete_sub 'web_weather';
    delete_sub 'web_weather_getData';
    sophia_command_del 'web.weather';
    delete_sub 'deinit_web_weather';
}

sub web_weather_getData {
    my ($obj, @selectors) = @_;
    $obj = ${$obj};

    my @results;
    push @results, $obj->findnodes($_)->[0]->to_literal for @selectors;
    return \@results;
}

sub web_weather {
    my $args = $_[0];
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    my $idx = index $content, ' ';
    return if $idx == -1;

    $content = substr $content, $idx + 1;
    $content =~ s/ /+/g;

    my $objXML = loadXML(sprintf('http://api.wunderground.com/auto/wui/geo/WXCurrentObXML/index.xml?query=%s', $content));
    return if !$objXML;
    $objXML = ${$objXML};

    my $dataset = web_weather_getData(\$objXML, '//display_location/full', '//station_id', '//weather', '//temperature_string', '//relative_humidity', '//wind_string', '//wind_dir', '//wind_degrees', '//wind_mph', '//dewpoint_string', '//pressure_string', '//visibility_mi');

    my $result = sprintf('%s (%s)  %s, %s.  Humidity: %s.  Wind: %s (%s, %s degrees at %s mph).  Dewpoint: %s.  Air pressure: %s.  Visibility: %s miles.', @{$dataset});
    
    my $sophia = ${$args->[HEAP]->{sophia}};
    $sophia->yield(privmsg => $where->[0] => $result);
}

1;
