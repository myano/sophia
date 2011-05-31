use strict;
use warnings;

sophia_module_add('admin.kickban', '1.0', \&init_admin_kickban, \&deinit_admin_kickban);

sub init_admin_kickban {
    sophia_command_add('admin.kickban', \&admin_kickban, 'Bans and kicks the user if bot is a chan op.', '', SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP);
    sophia_global_command_add('kickban', \&admin_kickban, 'Bans and kicks the user if bot is a chan op.', '', SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP);

    return 1;
}

sub deinit_admin_kickban {
    delete_sub 'init_admin_kickban';
    delete_sub 'admin_kickban';
    sophia_command_del 'admin.kickban';
    sophia_global_command_del 'kickban';
    delete_sub 'deinit_admin_kickban';
}

sub admin_kickban {
    my $args = $_[0];
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    
    my $idx = index $content, ' ';
    return unless $idx > -1;

    $content = substr $content, $idx + 1;
    $content =~ s/^\s+//;

    $idx = index $content, ' ';
    return unless $idx > -1;

    my $target = substr $content, 0, $idx;
    my $kick_msg = substr $content, $idx + 1;

    my $sophia = ${$args->[HEAP]->{sophia}};
    $sophia->yield( mode => $where->[0] => '+b' => $target );
    $sophia->yield( kick => $where->[0] => $target => $kick_msg );
}

1;
