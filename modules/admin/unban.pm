use strict;
use warnings;

sophia_module_add('admin.unban', '1.0', \&init_admin_unban, \&deinit_admin_unban);

sub init_admin_unban {
    sophia_command_add('admin.unban', \&admin_unban, 'Unbans the user/hostmask.', '');
    sophia_global_command_add('unban', \&admin_unban, 'Unbans the user/hostmask.', '');

    return 1;
}

sub deinit_admin_unban {
    delete_sub 'init_admin_unban';
    delete_sub 'admin_unban';
    sophia_command_del 'admin.unban';
    sophia_global_command_del 'unban';
    delete_sub 'deinit_admin_unban';
}

sub admin_unban {
    my $param = $_[0];
    my @args = @{$param};
    my ($heap, $who, $where, $content) = @args[HEAP, ARG0 .. ARG2];

    my $perms = sophia_get_host_perms($who, $where->[0]);
    return unless $perms & SOPHIA_ACL_ADMIN;

    my $idx = index $content, ' ';
    return unless $idx > -1;

    $content = substr $content, $idx + 1;
    $content =~ s/^\s+//;
    return unless $content;

    my $sophia = ${$heap->{sophia}};
    my @parts = split / /, $content;

    $sophia->yield( mode => $where->[0] => sprintf('-%s', 'b' x scalar(@parts)) => $content );
}

1;
