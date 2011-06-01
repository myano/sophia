use strict;
use warnings;
use feature 'switch';

sophia_module_add('acl.chanflags', '1.0', \&init_acl_chanflags, \&deinit_acl_chanflags);

sub init_acl_chanflags {
    sophia_command_add('acl.chanflags', \&acl_chanflags, 'Modifies the ACL channel flags for a group or a user.', '', SOPHIA_ACL_FOUNDER);
    sophia_event_privmsg_hook('acl.chanflags', \&acl_chanflags, 'Modifies the ACL channel flags for a group or a user.', '', SOPHIA_ACL_FOUNDER);

    return 1;
}

sub deinit_acl_chanflags {
    delete_sub 'init_acl_chanflags';
    delete_sub 'acl_chanflags';
    delete_sub 'acl_chanflags_group';
    delete_sub 'acl_chanflags_user';
    sophia_command_del 'acl.chanflags';
    sophia_event_privmsg_dehook 'acl.chanflags';
    delete_sub 'deinit_acl_chanflags';
}

sub acl_chanflags {
    my ($args, $target) = @_;
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    $target //= $where->[0];

    my @opts = split /\s+/, $content;
    return unless scalar(@opts) == 5;

    my $opt = $opts[1];
    $opt = uc $opt;

    my $sophia = $args->[HEAP]->{sophia};

    given ($opt) {
        when ('GROUP')  { acl_chanflags_group($sophia, $target, \@opts); }
        when ('USER')   { acl_chanflags_user($sophia, $target, \@opts);  }
    }
}

sub acl_chanflags_group {
    my ($sophia, $target, $opts) = @_;
    $sophia = ${$sophia};

    ($opts->[2], $opts->[3]) = (lc $opts->[2], lc $opts->[3]);

    if (!sophia_group_exists($opts->[2])) {
        $sophia->yield(privmsg => $target => sprintf('Group %1$s%2$s%1$s does not exist.', "\x02", $opts->[2]));
        return;
    }

    sophia_group_chanflags($opts->[2], $opts->[3], $opts->[4]);

    my $groups = &sophia_acl_groups;
    my $group = $groups->{$opts->[2]};

    $sophia->yield(privmsg => $target => sprintf('Channel %1$s%2$s%1$s flags for group %1$s%3$s%1$s modified to %1$s%2$s%1$s.', "\x02", $opts->[3], $opts->[2], sophia_acl_bits2flags($group->{CHANNELS}{$opts->[3]})));
}

sub acl_chanflags_user {
    my ($sophia, $target, $opts) = @_;
    $sophia = ${$sophia};

    ($opts->[2], $opts->[3]) = (lc $opts->[2], lc $opts->[3]);

    unless (sophia_user_exists($opts->[2])) {
        $sophia->yield(privmsg => $target => sprintf('User %1$s%2$s%1$s does not exist.', "\x02", $opts->[2]));
        return;
    }

    sophia_user_chanflags($opts->[2], $opts->[3], $opts->[4]);

    my $users = &sophia_acl_users;
    my $user = $users->{$opts->[2]};

    $sophia->yield(privmsg => $target => sprintf('Channel %1$s%2$s%1$s flags for user %1$s%3$s%1$s modified to %1$s%4$s%1$s.', "\x02", $opts->[3], $opts->[2], sophia_acl_bits2flags($user->{CHANNELS}{$opts->[3]})));
}

1;
