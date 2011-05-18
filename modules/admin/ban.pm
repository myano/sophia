use strict;
use warnings;

sophia_module_add('admin.ban', '1.0', \&init_admin_ban, \&deinit_admin_ban);

sub init_admin_ban {
    sophia_command_add('admin.ban', \&admin_ban, 'Bans the user/hostmask.', '', SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP);
    sophia_global_command_add('ban', \&admin_ban, 'Bans the user/hostmask.', '', SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP);

    return 1;
}

sub deinit_admin_ban {
    delete_sub 'init_admin_ban';
    delete_sub 'admin_ban';
    sophia_command_del 'admin.ban';
    sophia_global_command_del 'ban';
    delete_sub 'deinit_admin_ban';
}

sub admin_ban {
    my $param = $_[0];
    my @args = @{$param};
    my ($where, $content) = @args[ARG1,ARG2];

    my $idx = index $content, ' ';
    return unless $idx > -1;

    $content = substr $content, $idx + 1;
    return unless $content;

    my $sophia = ${$args[HEAP]->{sophia}};
    my @parts = split / /, $content;

    $sophia->yield( mode => $where->[0] => sprintf('+%s', 'b' x scalar(@parts)) => $content );
}

1;
