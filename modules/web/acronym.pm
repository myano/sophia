use strict;
use warnings;

sophia_module_add('web.acronym', '2.0', \&init_web_acronym, \&deinit_web_acronym);

sub init_web_acronym {
    sophia_command_add('web.acronym', \&web_acronym, 'Tries to find the meaning of the acronym.', '');

    return 1;
}

sub deinit_web_acronym {
    delete_sub 'init_web_acronym';
    delete_sub 'web_acronym';
    sophia_command_del 'web.acronym';
    sophia_command_del 'web.abbrev';
    delete_sub 'deinit_web_acronym';
}

my $max = 10;
sub web_acronym {
    my $args = $_[0];
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);

    $content = substr $content, index($content, ' ') + 1;
    $content =~ s/ /+/g;

    my $response = curl_get(sprintf('http://acronyms.thefreedictionary.com/%s', $content));
    return unless $response;

    my @acronyms;
    my ($idx, $acronym) = (0, '');

    FOR: for (1 .. $max) {
        $idx = index $response, '<td class=acr>', $idx;
        last FOR unless $idx > -1;

        $idx = index $response, '<td>', $idx + 1;
        
        $acronym = substr $response, $idx + 4, index($response, '</td>', $idx + 1) - $idx - 4;
        $acronym =~ s/<[^>]+>//g;

        push @acronyms, $acronym;

        $idx += 3;
    }

    my $sophia = $args->[HEAP]->{sophia};

    if (scalar(@acronyms) == 0) {
        $sophia->yield(privmsg => $where->[0] => 'Acronym not found in the database.');
        return;
    }

    $sophia->yield(privmsg => $where->[0] => join ', ', @acronyms);
}

1;
