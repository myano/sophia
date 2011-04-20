use strict;
use warnings;

sophia_module_add('web.urltitle', '1.0', \&init_web_urltitle, \&deinit_web_urltitle);

sub init_web_urltitle {
    sophia_event_public_hook('web.urltitle', \&web_urltitle, 'Displays the title for the posted URL.', '');

    return 1;
}

sub deinit_web_urltitle {
    delete_sub 'init_web_urltitle';
    delete_sub 'web_urltitle';
    sophia_event_public_dehook 'web.urltitle';
    delete_sub 'deinit_web_urltitle';
}

sub web_urltitle {
    my $param = $_[0];
    my @args = @{$param};
    my ($where, $content) = ($args[ARG1], $args[ARG2]);

    return unless $content =~ /^http:\/\/[^ ]+$/;

    my $objHTTP = get_file_contents(\$content);
    $objHTTP = ${$objHTTP};

    return if index($objHTTP, '<title>') == -1;

    my $start = index($objHTTP, '<title>') + 7;
    my $end = index($objHTTP, '</title>') - $start;
    my $title = substr $objHTTP, $start, $end;
    $title =~ s/^\s+//;
    $title =~ s/\n//;
    $title =~ s/\s{2,}/ /;
    sophia_write( \$where->[0], \$title );
}

1;
