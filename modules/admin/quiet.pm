use strict;
use warnings;

sophia_module_add('admin.quiet', '1.0', \&init_admin_quiet, \&deinit_admin_quiet);

sub init_admin_quiet {
    sophia_command_add('admin.quiet', \&admin_quiet, 'Quiets the user/hostmask.', '', SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP);
    sophia_global_command_add('quiet', \&admin_quiet, 'Quiets the user/hostmask.', '', SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP);

    return 1;
}

sub deinit_admin_quiet {
    delete_sub 'init_admin_quiet';
    delete_sub 'admin_quiet';
    sophia_command_del 'admin.quiet';
    sophia_global_command_del 'quiet';
    delete_sub 'deinit_admin_quiet';
}

sub admin_quiet {
    my $args = $_[0];
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);

    my $idx = index $content, ' ';
    return unless $idx > -1;

    $content = substr $content, $idx + 1;
    $content =~ s/^\s+//;
    return unless $content;

    my $sophia = ${$args->[HEAP]->{sophia}};
    my @parts = split / /, $content;

    $sophia->yield( mode => $where->[0] => sprintf('+%s', 'q' x scalar(@parts)) => $content );
}

1;
