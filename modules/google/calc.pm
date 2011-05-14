use strict;
use warnings;

sophia_module_add('google.calc', '1.0', \&init_google_calc, \&deinit_google_calc);

sub init_google_calc {
    sophia_command_add('google.calc', \&google_calc, 'Uses Google for calculating stuff.', '');
    sophia_global_command_add('calc', \&google_calc, 'Uses Google for calculating stuff.', '');

    return 1;
}

sub deinit_google_calc {
    delete_sub 'init_google_calc';
    delete_sub 'google_calc';
    sophia_command_del 'google.calc';
    delete_sub 'deinit_google_calc';
}

sub google_calc {
    my $param = $_[0];
    my @args = @{$param};
    my ($where, $content) = ($args[ARG1], $args[ARG2]);
    $content = substr $content, index($content, ' ') + 1;

    $content =~ s/\+/\%2B/g;
    $content =~ s/\^/\%5E/g;
    $content =~ s/ /\+/g;

    my $response = curl_get(sprintf('http://www.google.com/search?q=%s', $content));
    return unless $response;

    if ($response =~ /<h(2|3) class=r( [^>]+)?><b>(.+?) = (.+?)<\/b><\/h(2|3)>/) {
        my ($eq, $ans) = ($3, $4);
        $eq =~ s/<font size=-2> <\/font>/,/g;
        $ans =~ s/<sup>([^<]+)<\/sup>/^$1/g;
        $ans =~ s/<font size=-2> <\/font>/,/g;

        sophia_write( \$where->[0], \sprintf('%s = %s', $eq, $ans) );
    }
}

1;
