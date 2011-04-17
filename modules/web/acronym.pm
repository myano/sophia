use strict;
use warnings;

sophia_module_add('web.acronym', '1.0', \&init_web_acronym, \&deinit_web_acronym);

sub init_web_acronym {
    sophia_command_add('web.acronym', \&web_acronym, 'Tries to find the meaning of the acronym.', '');
    sophia_command_add('web.abbrev', \&web_acronym, 'Tries to find the meaning of the acronym.', '');

    return 1;
}

sub deinit_web_acronym {
    delete_sub 'init_web_acronym';
    delete_sub 'web_acronym';
    sophia_command_del 'web.acronym';
    sophia_command_del 'web.abbrev';
    delete_sub 'deinit_web_acronym';
}

sub web_acronym {
    my $param = $_[0];
    my @args = @{$param};
    my ($where, $content) = @args[ARG1 .. ARG2];
    $content = substr $content, index($content, ' ') + 1;
    $content =~ s/ /+/g;

    my $objHTTP = get_file_contents(\sprintf('http://www.all-acronyms.com/%s', $content));
    $objHTTP = ${$objHTTP};

    my $idx = index $objHTTP, '<div id="terms">';
    if ($idx > 0) {
        my $terms = substr $objHTTP, $idx, index($objHTTP, '</div>', $idx) - $idx;
        my @matches = ($terms =~ m/>([^<]+)</msg);
        my ($output, $first, $max) = ('', 1, 10);
        MATCHES: for (@matches) {
            next MATCHES if $_ eq '&nbsp;';
            $output .= ', ' unless $first;
            $output .= $_;
            $first = 0;
            last MATCHES if --$max < 1;
        }
        sophia_write(\$where->[0], \$output);
    }
    else {
        sophia_write(\$where->[0], \'Acronym not found in database.');
        return;
    }
}

1;
