use strict;
use warnings;

sophia_module_add('acl.usergroup', '1.0', \&init_acl_usergroup, \&deinit_acl_usergroup);

sub init_acl_usergroup {
    sophia_command_add('acl.usergroup', \&acl_usergroup, 'Adds a user to a group.', '', SOPHIA_ACL_FOUNDER);
    sophia_event_privmsg_hook('acl.usergroup', \&acl_usergroup, 'Adds a user to a group.', '', SOPHIA_ACL_FOUNDER);

    return 1;
}

sub deinit_acl_usergroup {
    delete_sub 'init_acl_usergroup';
    delete_sub 'acl_usergroup';
    sophia_command_del 'acl.usergroup';
    sophia_event_privmsg_dehook 'acl.usergroup';
    delete_sub 'deinit_acl_usergroup';
}

sub acl_usergroup {
    my ($args, $target) = @_;
    my @args = @{$args};
    my ($where, $content) = @args[ARG1,ARG2];
    $target ||= $where->[0];

    my @opts = split /\s+/, $content;
    return unless scalar(@opts) == 3;

    my $sophia = ${$args[HEAP]->{sophia}};

    map { $_ = lc; } @opts;

    if (!sophia_user_exists($opts[1])) {
        $sophia->yield(privmsg => $target => sprintf('User %1$s%2$s%1$s does not exist.', "\x02", $opts[1]));
        return;
    }

    if (!sophia_group_exists($opts[2])) {
        $sophia->yield(privmsg => $target => sprintf('Group %1$s%2$s%1$s does not exist.', "\x02", $opts[2]));
        return;
    }

    sophia_user_group_add($opts[1], $opts[2]);
    $sophia->yield(privmsg => $target => sprintf('User %1$s%2$s%1$s added to group %1$s%3$s%1$s.', "\x02", $opts[1], $opts[2]));
}

1;
