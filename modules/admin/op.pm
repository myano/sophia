use strict;
use warnings;

sophia_module_add('admin.op', '1.0', \&init_admin_op, \&deinit_admin_op);

sub init_admin_op {
    sophia_command_add('admin.op', \&admin_op, 'Ops the user/hostmask.', '');
    sophia_global_command_add('op', \&admin_op, 'Ops the user/hostmask.', '');

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
    my $param = $_[0];
    my @args = @{$param};
    my ($heap, $who, $where, $content) = @args[HEAP, ARG0 .. ARG2];

    my $perms = sophia_get_host_perms($who, $where->[0]);
    return unless $perms & SOPHIA_ACL_OP || $perms & SOPHIA_ACL_AUTOOP;

    my $idx = index $content, ' ';
    unless ($idx == -1) {
        $content = substr $content, $idx + 1;
        $content =~ s/^\s+//;
    }

    my $sophia = ${$heap->{sophia}};
    unless ($idx > -1 && $content) {
        $content = substr $who, 0, index($who, '!');
        $sophia->yield( mode => $where->[0] => "+o" => $content );
        return;
    }

    my @parts = split / /, $content;
    $sophia->yield( mode => $where->[0] => sprintf('+%s', 'o' x scalar(@parts)) => $content );
}

1;
