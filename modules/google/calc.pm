use strict;
use warnings;
use URI::Escape;

sophia_module_add('google.calc', '1.0', \&init_google_calc, \&deinit_google_calc);

sub init_google_calc {
    sophia_global_command_add('gcalc', \&google_calc, 'Uses Google for calculating stuff.', '');

    return 1;
}

sub deinit_google_calc {
    delete_sub 'init_google_calc';
    delete_sub 'google_calc';
    sophia_command_del 'google.calc';
    delete_sub 'deinit_google_calc';
}

sub google_calc {
    my $args = $_[0];
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    $content = substr $content, index($content, ' ') + 1;

    #my $response = curl_get(sprintf('http://www.google.com/search?q=%s', $content));
    #http://www.google.com/ig/calculator?q=30+usd+in+euro
    my $response = curl_get(sprintf('http://www.google.com/ig/calculator?q=%s', uri_escape($content)));
    return unless $response;

    return unless $response =~ /error:\s*"0?"/;

    my $sophia = ${$args->[HEAP]->{sophia}};
    my $reply = '';

    my $idx = index($response, 'lhs: "') + 6;
    $reply .= substr $response, $idx, index($response, '",', $idx) - $idx;
    
    $idx = index($response, 'rhs: "') + 6;
    $reply .= sprintf(' = %s', substr($response, $idx, index($response, '",', $idx) - $idx));

    $sophia->yield(privmsg => $where->[0] => $reply);
}

1;
