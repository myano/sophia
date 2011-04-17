use strict;
use warnings;

sophia_module_add("public.urltitle", "1.0", \&init_public_urltitle, \&deinit_public_urltitle);

sub init_public_urltitle {
    sophia_command_add("public.urltitle", \&public_urltitle, "Displays the title for posted URLs.", "");

    return 1;
}

sub deinit_public_urltitle {
    delete_sub "init_public_urltitle";
    delete_sub "public_urltitle";
    sophia_command_del "public.urltitle";
    delete_sub "deinit_public_urltitle";
}

sub public_urltitle {
    my $param = $_[0];
    my @args = @{$param};
    my ($where, $content) = ($args[ARG1], $args[ARG2]);

    return unless $content =~ /^http:\/\/[^ ]+$/;

    my $objHTTP = get_file_contents($content);
    return if index($objHTTP, "<title>") == -1;

    my $start = index($objHTTP, "<title>") + 7;
    my $end = index($objHTTP, "</title>") - $start;
    my $title = substr $objHTTP, $start, $end;
    $title =~ s/^\s+//;
    $title =~ s/\n//;
    $title =~ s/\s{2,}/ /;
    sophia_write( \$where->[0], \$title );
}

1;
