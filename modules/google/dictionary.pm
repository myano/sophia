use strict;
use warnings;

sophia_module_add('google.dictionary', '2.0', \&init_google_dictionary, \&deinit_google_dictionary);

sub init_google_dictionary {
    sophia_command_add('google.dict', \&google_dictionary, 'Defines a word.', '');

    return 1;
}

sub deinit_google_dictionary {
    delete_sub 'init_google_dictionary';
    delete_sub 'google_dictionary';
    delete_sub 'google_unescape';
    sophia_command_del 'google.dict';
    delete_sub 'deinit_google_dictionary';
}

my $max_entries = 3;

sub google_dictionary_unescape {
    my $str = $_[0];
    $str =~ s/\\x3c/</g;
    $str =~ s/\\x3e/>/g;
    $str =~ s/<[^>]+>//g;
    $str =~ s/\\x(\d{2})/chr(hex($1))/eg;
    return $str;
}

sub google_dictionary {
    my $args = $_[0];
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    
    my $idx = index $content, ' ';
    return unless $idx > -1;

    $content = substr $content, $idx + 1;
    $content =~ s/ /+/g;
    $content =~ s/&/%26/g;

    my $response = curl_get(sprintf('http://www.google.com/dictionary/json?callback=dict_api.callbacks.id100&sl=en&tl=en&restrict=pr%sde&client=te&q=%s', '%2C', $content));
    return unless $response;

    my $sophia = ${$args->[HEAP]->{sophia}};

    $idx = index $response, '"query":"';
    unless ($idx > -1) {
        $sophia->yield(privmsg => $where->[0] => 'Term not found.');
        return;
    }
    $idx += 9;
    my $term = substr $response, $idx, index($response, '"', $idx) - $idx;

    my @results;
    my $result;
    $idx = 0;
    
    ENTRY: for (1 .. $max_entries) {
        $idx = index $response, '"type":"meaning"', $idx;
        last ENTRY unless $idx > -1;

        $idx = index $response, '"text":"', $idx + 1;
        last ENTRY unless $idx > -1;

        $idx += 8;
        
        $result = substr($response, $idx, index($response, '"', $idx) - $idx);
        $result = google_dictionary_unescape($result);
        $result =~ s/\[\d+\]//g;
        push @results, sprintf('%1$s%2$s:%1$s %3$s', "\x02", $term, decode_entities($result));
    }

    return unless $#results + 1;

    $sophia->yield(privmsg => $where->[0] => $_) for @results;
}

1;
