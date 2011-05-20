use strict;
use warnings;

sophia_module_add('admin.deop', '1.0', \&init_admin_deop, \&deinit_admin_deop);

sub init_admin_deop {
    sophia_command_add('admin.deop', \&admin_deop, 'Deops the user/hostmask.', '', SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP);
    sophia_global_command_add('deop', \&admin_deop, 'Deops the user/hostmask.', '', SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP);

    return 1;
}

sub deinit_admin_deop {
    delete_sub 'init_admin_deop';
    delete_sub 'admin_deop';
    sophia_command_del 'admin.deop';
    sophia_global_command_del 'deop';
    delete_sub 'deinit_admin_deop';
}

sub admin_deop {
    my $args = $_[0];
    my ($who, $where, $content) = ($args->[ARG0], $args->[ARG1], $args->[ARG2]);

    my $idx = index $content, ' ';
    unless ($idx == -1) {
        $content = substr $content, $idx + 1;
        $content =~ s/^\s+//;
    }

    my $sophia = ${$args->[HEAP]->{sophia}};
    unless ($idx > -1 && $content) {
        $content = substr $who, 0, index($who, '!');
        $sophia->yield( mode => $where->[0] => "-o" => $content );
        return;
    }

    my @parts = split / /, $content;
    $sophia->yield( mode => $where->[0] => sprintf('-%s', 'o' x scalar(@parts)) => $content );
}

1;
