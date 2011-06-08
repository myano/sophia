use strict;
use warnings;

sophia_module_add('admin.ban', '2.0', \&init_admin_ban, \&deinit_admin_ban);

sub init_admin_ban {
    sophia_global_command_add('ban', \&admin_ban, 'Bans the user/hostmask.', '', SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP);
    sophia_event_privmsg_hook('sophia.ban', \&admin_ban, 'Bans the user/hostmask.', '', SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP);

    return 1;
}

sub deinit_admin_ban {
    delete_sub 'init_admin_ban';
    delete_sub 'admin_ban';
    sophia_global_command_del 'ban';
    sophia_event_privmsg_dehook 'sophia.ban';
    delete_sub 'deinit_admin_ban';
}

sub admin_ban {
    my ($args, $target) = @_;
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    my $target_chan = $where->[0];

    my @parts = split ' ', $content;

    # the first arg in @parts will be the command: !ban, so toss it out
    shift @parts;
    return if !$parts[0];

    # if privmsg, store the target channel
    $target_chan = $parts[0] and shift @parts if $target;

    return if !$parts[0];

    my $sophia = ${$args->[HEAP]->{sophia}};
    $sophia->yield( mode => $target_chan => sprintf('+%s', 'b' x ($#parts + 1)) => join ' ', @parts );
}

1;
