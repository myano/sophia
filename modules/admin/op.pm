use strict;
use warnings;

sophia_module_add('admin.op', '1.0', \&init_admin_op, \&deinit_admin_op);

sub init_admin_op {
    sophia_command_add('admin.op', \&admin_op, 'Ops the user/hostmask.', '', SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP);
    sophia_global_command_add('op', \&admin_op, 'Ops the user/hostmask.', '', SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP);

    return 1;
}

sub deinit_admin_op {
    delete_sub 'init_admin_op';
    delete_sub 'admin_op';
    sophia_command_del 'admin.op';
    sophia_global_command_del 'op';
    delete_sub 'deinit_admin_op';
}

sub admin_op {
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
        $sophia->yield( mode => $where->[0] => "+o" => $content );
        return;
    }

    my @parts = split /\s+/, $content;
    $sophia->yield( mode => $where->[0] => sprintf('+%s', 'o' x scalar(@parts)) => $content );
}

1;
