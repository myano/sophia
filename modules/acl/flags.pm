use strict;
use warnings;
use feature 'switch';

sophia_module_add('acl.flags', '1.0', \&init_acl_flags, \&deinit_acl_flags);

sub init_acl_flags {
    sophia_command_add('acl.flags', \&acl_flags, 'Modifies the ACL flags for a group or a user.', '');

    return 1;
}

sub deinit_acl_flags {
    delete_sub 'init_acl_flags';
    delete_sub 'acl_flags';
    delete_sub 'acl_flags_group';
    delete_sub 'acl_flags_user';
    sophia_command_del 'acl.flags';
    delete_sub 'deinit_acl_flags';
}

sub acl_flags {
    my $param = $_[0];
    my @args = @{$param};
    my ($who, $where, $content) = @args[ARG0 .. ARG2];

    my $perms = sophia_get_host_perms($who);
    return unless $perms & SOPHIA_ACL_FOUNDER;

    my @opts = split /\s+/, $content;
    return unless scalar(@opts) == 4;

    my $opt = $opts[1];
    $opt = uc $opt;

    my $sophia = ${$args[HEAP]->{sophia}};

    given ($opts[1]) {
        when ('GROUP')  { acl_flags_group(\$sophia, $where, \@opts); }
        when ('USER')   { acl_flags_user(\$sophia, $where, \@opts);  }
    }
}

sub acl_flags_group {
    my ($sophia, $where, $opts) = @_;
    $sophia = ${$sophia};
    my @opts = @{$opts};

    ($opts[2], $opts[3]) = (lc $opts[2], $opts[3]);

    if (!sophia_group_exists($opts[2])) {
        $sophia->yield(privmsg => $where->[0] => sprintf('Group %1$s%2$s%1$s does not exist.', "\x02", $opts[2]));
        return;
    }

   return unless sophia_group_flags($opts[2], $opts[3]);

    my $groups = &sophia_acl_groups;
    my $group = $groups->{$opts[2]};

    $sophia->yield(privmsg => $where->[0] => sprintf('Group %1$s%2$s%1$s flags modified to %1$s%3$s%1$s.', "\x02", $opts[2], sophia_acl_bits2flags($group->{FLAGS})));
}

sub acl_flags_user {
    my ($sophia, $where, $opts) = @_;
    $sophia = ${$sophia};
    my @opts = @{$opts};

    map { $_ = lc; } @opts;

    if (!sophia_user_exists($opts[2])) {
        $sophia->yield(privmsg => $where->[0] => sprintf('User %1$s%2$s%1$s does not exist.', "\x02", $opts[2]));
        return;
    }

    return unless sophia_user_flags($opts[2], $opts[3]);

    my $users = &sophia_acl_users;
    my $user = $users->{$opts[2]};

    $sophia->yield(privmsg => $where->[0] => sprintf('User %1$s%2$s%1$s flags modified to %1$s%3$s%1$s.', "\x02", $opts[2], sophia_acl_bits2flags($user->{FLAGS})));
}

1;
