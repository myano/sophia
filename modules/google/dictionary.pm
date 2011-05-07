use strict;
use warnings;

sophia_module_add('google.dictionary', '1.0', \&init_google_dictionary, \&deinit_google_dictionary);

sub init_google_dictionary {
    sophia_command_add('google.dict', \&google_dictionary, 'Defines a word.', '');
    sophia_global_command_add('dict', \&google_dictionary, 'Defines a word.', '');

    return 1;
}

sub deinit_google_dictionary {
    delete_sub 'init_google_dictionary';
    delete_sub 'google_dictionary';
    sophia_command_del 'google.dict';
    delete_sub 'deinit_google_dictionary';
}

my $max_entries = 2;
my $bold = POE::Component::IRC::Common::BOLD;

sub google_dictionary {
    my $param = $_[0];
    my @args = @{$param};
    my ($where, $content) = @args[ARG1, ARG2];
    
    my $idx = index $content, ' ';
    return unless $idx > -1;

    $content = substr $content, $idx + 1;
    $content =~ s/ /+/g;
    $content =~ s/&/%26/g;

    my $response = http_get(sprintf('http://www.google.com/dictionary/json?callback=dict_api.callbacks.id100&sl=en&tl=en&restrict=pr%2Cde&client=te&q=%s', $content));
    return unless $response;

    $idx = index $response, '"query":"';
    unless ($idx > -1) {
        sophia_write( \$where->[0], \'Term not found.' );
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
        $result =~ s/\\x22/"/g;
        $result =~ s/\\x27/'/g;
        $result =~ s/\\x3c\/?em\\x3e//g;
        push @results, sprintf($bold . '%s: ' . $bold . '%s', $term, $result);
    }

    return unless scalar(@results);

    sophia_write( \$where->[0], \@results );
}

1;
