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
    sophia_command_del 'google.weather';
    delete_sub 'deinit_google_weather';
}

sub google_weather {
    my $args = $_[0];
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    $content = substr $content, index($content, ' ') + 1;
    $content =~ s/ /+/g;

    my $objXML = loadXML(sprintf('http://www.google.com/ig/api?weather=%s', $content));
    return unless $objXML;
    $objXML = ${$objXML};

    my $output = '';
    
    $output .= $objXML->findnodes('//city')->shift()->getAttribute('data');
    $output .= '  --- ';

    my $condition = $objXML->findnodes('//current_conditions/condition')->shift()->getAttribute('data');
    my $tempf = $objXML->findnodes('//current_conditions/temp_f')->shift()->getAttribute('data');
    $output .= sprintf('Now: %s (%s).   ', $condition, $tempf);

    my @forecasts = $objXML->findnodes('//forecast_conditions');
    my ($day, $day_low, $day_high, $day_cond) = '';
    my $today = 1;

    for (@forecasts) {
        $day = $_->findnodes('./day_of_week')->shift();
        $day_low = $_->findnodes('./low')->shift();
        $day_high = $_->findnodes('./high')->shift();
        $day_cond = $_->findnodes('./condition')->shift();
        $day = $day->getAttribute('data');
        $day = 'Today' if $today; $today = 0;
        $output .= sprintf('%s: %s (%s | %s).   ', $day, $day_cond->getAttribute('data'), $day_high->getAttribute('data'), $day_low->getAttribute('data'));
    }

    my $sophia = ${$args->[HEAP]->{sophia}};
    $sophia->yield(privmsg => $where->[0] => $output);
}

1;
