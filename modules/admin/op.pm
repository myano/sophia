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
    delete_sub 'deinit_admin_op';
}

sub admin_op {
    my $param = $_[0];
    my @args = @{$param};
    my ($who, $where, $content) = @args[ARG0 .. ARG2];
    return unless is_admin($who);

    my $idx = index $content, ' ';
    unless ($idx == -1) {
        $content = substr $content, $idx + 1;
        $content =~ s/^\s+//;
    }

    unless ($idx > -1 && $content) {
        $content = substr $who, 0, index($who, '!');
        $sophia::sophia->yield( mode => $where->[0] => "+o" => $content );
        return;
    }

    my @parts = split / /, $content;
    $sophia::sophia->yield( mode => $where->[0] => sprintf('+%s', 'o' x scalar(@parts)) => $content );
}

1;
