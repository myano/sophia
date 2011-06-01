use strict;
use warnings;
use feature 'switch';

sophia_module_add('acl.flags', '1.0', \&init_acl_flags, \&deinit_acl_flags);

sub init_acl_flags {
    sophia_command_add('acl.flags', \&acl_flags, 'Modifies the ACL flags for a group or a user.', '', SOPHIA_ACL_FOUNDER);
    sophia_event_privmsg_hook('acl.flags', \&acl_flags, 'Modifies the ACL flags for a group or a user.', '', SOPHIA_ACL_FOUNDER);

    return 1;
}

sub deinit_acl_flags {
    delete_sub 'init_acl_flags';
    delete_sub 'acl_flags';
    delete_sub 'acl_flags_group';
    delete_sub 'acl_flags_user';
    sophia_command_del 'acl.flags';
    sophia_event_privmsg_dehook 'acl.flags';
    delete_sub 'deinit_acl_flags';
}

sub acl_flags {
    my ($args, $target) = @_;
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    $target //= $where->[0];

    my @opts = split /\s+/, $content;
    return unless scalar(@opts) == 4;

    my $opt = $opts[1];
    $opt = uc $opt;

    my $sophia = $args->[HEAP]->{sophia};

    given ($opt) {
        when ('GROUP')  { acl_flags_group($sophia, $target, \@opts); }
        when ('USER')   { acl_flags_user($sophia, $target, \@opts);  }
    }
}

sub acl_flags_group {
    my ($sophia, $target, $opts) = @_;
    $sophia = ${$sophia};

    ($opts->[2], $opts->[3]) = (lc $opts->[2], $opts->[3]);

    if (!sophia_group_exists($opts->[2])) {
        $sophia->yield(privmsg => $target => sprintf('Group %1$s%2$s%1$s does not exist.', "\x02", $opts->[2]));
        return;
    }

   return unless sophia_group_flags($opts->[2], $opts->[3]);

    my $groups = &sophia_acl_groups;
    my $group = $groups->{$opts->[2]};

    $sophia->yield(privmsg => $target => sprintf('Group %1$s%2$s%1$s flags modified to %1$s%3$s%1$s.', "\x02", $opts->[2], sophia_acl_bits2flags($group->{FLAGS})));
}

sub acl_flags_user {
    my ($sophia, $target, $opts) = @_;
    $sophia = ${$sophia};

    $opts->[2] = lc $opts->[2];

    if (!sophia_user_exists($opts->[2])) {
        $sophia->yield(privmsg => $target => sprintf('User %1$s%2$s%1$s does not exist.', "\x02", $opts->[2]));
        return;
    }

    return unless sophia_user_flags($opts->[2], $opts->[3]);

    my $users = &sophia_acl_users;
    my $user = $users->{$opts->[2]};

    $sophia->yield(privmsg => $target => sprintf('User %1$s%2$s%1$s flags modified to %1$s%3$s%1$s.', "\x02", $opts->[2], sophia_acl_bits2flags($user->{FLAGS})));
}

1;
