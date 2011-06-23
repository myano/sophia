use strict;
use warnings;

sophia_module_add('google.search', '1.0', \&init_google_search, \&deinit_google_search);

sub init_google_search {
    sophia_command_add('google.search', \&google_search, 'Searches google for results.', '');

    return 1;
}

sub deinit_google_search {
    delete_sub 'init_google_search';
    delete_sub 'google_search';
    delete_sub 'google_unescape';
    sophia_command_del 'google.search';
    delete_sub 'deinit_google_search';
}

sub google_search_unescape {
    my $str = $_[0];
    $str =~ s/\\u(.{4})/chr(hex($1))/eg;
    return $str;
}

my $max_entries = 3;

sub google_search {
    my $args = $_[0];
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);

    my $idx = index $content, ' ';
    return if $idx == -1;

    $content = substr $content, $idx + 1;
    return unless $content;

    $content =~ s/ /+/g;
    $content =~ s/&/%26/g;

    my $response = curl_get(sprintf('http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=%s', $content));
    return unless $response;

    my @results;
    my ($result, $endi) = ('', 0);
    $idx = 0;
    
    for (1 .. $max_entries) {
        $idx = index $response, '"unescapedUrl":"', $idx;
        last if $idx == -1;
        $idx += 16;

        $endi = index $response, '"', $idx;
        last if $endi == -1;

        $result = substr $response, $idx, $endi - $idx;
        $result = google_search_unescape($result);
        $result .= ' - ';

        $idx = index $response, '"titleNoFormatting":"', $endi;
        last if $idx == -1;
        $idx += 21;

        $endi = index $response, '"', $idx;
        last if $endi == -1;

        $result .= decode_entities(
            google_search_unescape( substr($response, $idx, $endi - $idx) )
        );
        push @results, $result;
    }

    return unless $#results + 1;

    my $sophia = $args->[HEAP]->{sophia};
    $sophia->yield(privmsg => $where->[0] => $_) for @results;
}

1;
