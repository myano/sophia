use strict;
use warnings;

sophia_module_add('google.weather', '1.0', \&init_google_weather, \&deinit_google_weather);

sub init_google_weather {
    sophia_command_add('google.weather', \&google_weather, 'Shows the weather for the specified location.', '');

    return 1;
}

sub deinit_google_weather {
    delete_sub 'init_google_weather';
    delete_sub 'google_weather';
    delete_sub 'google_weather_getData';
    sophia_command_del 'google.weather';
    delete_sub 'deinit_google_weather';
}

sub google_weather_getData {
    my ($obj, @selectors) = @_;
    $obj = ${$obj};

    my @results;
    push @results, $obj->findnodes($_)->[0]->getAttribute('data') for @selectors;
    return \@results;
}

sub google_weather {
    my $args = $_[0];
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    my $idx = index $content, ' ';
    return if $idx == -1;

    $content = substr $content, $idx + 1;
    $content =~ s/ /+/g;

    my $objXML = loadXML(sprintf('http://www.google.com/ig/api?weather=%s', $content));
    return unless $objXML;
    $objXML = ${$objXML};

    my @messages;
    my $dataset = google_weather_getData(\$objXML, '//city', '//current_conditions/condition', '//current_conditions/temp_f', '//current_conditions/temp_c', '//current_conditions/humidity', '//current_conditions/wind_condition');
    push @messages, sprintf('%s  --  Now: %s (%s F / %s C).   Humidity: %s.   Wind: %s.', @{$dataset});

    my @forecasts = $objXML->findnodes('//forecast_conditions');
    my $line = '';
    for (@forecasts) {
        $dataset = google_weather_getData(\$_, './day_of_week', './condition', './low', './high');
        $line .= sprintf('%s: %s (%s F | %s F).   ', @{$dataset});
    }
    push @messages, $line;

    my $sophia = ${$args->[HEAP]->{sophia}};
    $sophia->yield(privmsg => $where->[0] => $_) for @messages;
}

1;
