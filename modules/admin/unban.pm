use strict;
use warnings;

sophia_module_add('admin.unban', '2.0', \&init_admin_unban, \&deinit_admin_unban);

sub init_admin_unban {
    sophia_global_command_add('unban', \&admin_unban, 'Unbans the user/hostmask.', '', SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP);
    sophia_event_privmsg_hook('sophia.unban', \&admin_unban, 'Unbans the user/hostmask.', '', SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP);

    return 1;
}

sub deinit_admin_unban {
    delete_sub 'init_admin_unban';
    delete_sub 'admin_unban';
    sophia_global_command_del 'unban';
    sophia_event_privmsg_dehook 'sophia.unban';
    delete_sub 'deinit_admin_unban';
}

sub admin_unban {
    my ($args, $target) = @_;
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    my $target_chan = $where->[0];

    my @parts = split /\s+/, $content;

    # the first arg in @parts will be the command: !unban, so toss it out
    shift @parts;
    return if !$parts[0];

    # if privmsg, store the target channel
    $target_chan = $parts[0] and shift @parts if $target;

    return if !$parts[0];

    my $sophia = ${$args->[HEAP]->{sophia}};
    $sophia->yield( mode => $target_chan => sprintf('-%s', 'b' x ($#parts + 1)) => join ' ', @parts );
}

1;
