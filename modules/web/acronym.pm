use strict;
use warnings;

sophia_module_add('web.acronym', '1.0', \&init_web_acronym, \&deinit_web_acronym);

sub init_web_acronym {
    sophia_command_add('web.acronym', \&web_acronym, 'Tries to find the meaning of the acronym.', '');
    sophia_global_command_add('acronym', \&web_acronym, 'Tries to find the meaning of the acronym', '');

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
    my $param = $_[0];
    my @args = @{$param};
    my ($where, $content) = @args[ARG1 .. ARG2];
    $content = substr $content, index($content, ' ') + 1;
    $content =~ s/ /+/g;

    my $objHTTP = get_file_contents(\sprintf('http://acronyms.thefreedictionary.com/%s', $content));
    $objHTTP = ${$objHTTP};

    my @acronyms;
    my ($idx, $acronym) = (0, '');

    FOR: for (1 .. $max) {
        $idx = index $objHTTP, '<td class=acr>', $idx;
        last FOR unless $idx > -1;

        $idx = index $objHTTP, '<td>', $idx + 1;
        
        $acronym = substr $objHTTP, $idx + 4, index($objHTTP, '</td>', $idx + 1) - $idx - 4;
        $acronym =~ s/<[^>]+>//g;

        push @acronyms, $acronym;

        $idx += 3;
    }

    if (scalar(@acronyms) == 0) {
        sophia_write( \$where->[0], \'Acronym not found in the database.' );
        return;
    }
    sophia_write(\$where->[0], \join(', ', @acronyms));
}

1;
