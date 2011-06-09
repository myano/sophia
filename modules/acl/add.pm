use strict;
use warnings;
use feature 'switch';

sophia_module_add('acl.add', '1.0', \&init_acl_add, \&deinit_acl_add);

sub init_acl_add {
   sophia_command_add('acl.add', \&acl_add, 'Adds an entry to sophia\'s ACL.', '', SOPHIA_ACL_FOUNDER);
   sophia_event_privmsg_hook('acl.add', \&acl_add, 'Adds an entry to sophia\' ACL.', '', SOPHIA_ACL_FOUNDER);

   return 1;
}

sub deinit_acl_add {
    delete_sub 'init_acl_add';
    delete_sub 'acl_add';
    delete_sub 'acl_add_group';
    delete_sub 'acl_add_host';
    delete_sub 'acl_add_user';
    sophia_command_del 'acl.add';
    sophia_event_privmsg_dehook 'acl.add';
    delete_sub 'deinit_acl_add';
}

sub acl_add {
    my ($args, $target) = @_;
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    $target //= $where->[0];

    my @opts = split ' ', $content;
    return unless scalar(@opts) == 4;

    my $opt = $opts[1];
    $opt = uc $opt;

    my $sophia = $args->[HEAP]->{sophia};

    given ($opt) {
        when ('GROUP')  { acl_add_group($sophia, $target, \@opts); }
        when ('HOST')   { acl_add_host($sophia, $target, \@opts);  }
        when ('USER')   { acl_add_user($sophia, $target, \@opts);  }
    }
}

sub acl_add_group {
    my ($sophia, $target, $opts) = @_;
    $sophia = ${$sophia};

    $opts->[2] = lc $opts->[2];

    if (sophia_group_exists($opts->[2])) {
        $sophia->yield(privmsg => $target => sprintf('Group %1$s%2$s%1$s already exists.', "\x02", $opts->[2]));
        return;
    }

    sophia_group_add($opts->[2], $opts->[3]);
    $sophia->yield(privmsg => $target => sprintf('Group %1$s%2$s%1$s added.', "\x02", $opts->[2]));
}

sub acl_add_host {
    my ($sophia, $target, $opts) = @_;
    $sophia = ${$sophia};

    ($opts->[2], $opts->[3]) = (lc $opts->[2], lc $opts->[3]);

    if (!sophia_user_exists($opts->[2])) {
        $sophia->yield(privmsg => $target => sprintf('User %1$s%2$s%1$s does not exist.', "\x02", $opts->[2]));
        return;
    }

    if ($opts->[3] !~ /^[^!]+![^@]+@.+$/) {
        $sophia->yield(privmsg => $target => 'Invalid hostmask.');
        return;
    }

    sophia_userhost_add($opts->[2], $opts->[3]);
    $sophia->yield(privmsg => $target => sprintf('Host %1$s%2$s%1$s added to user %1$s%3$s%1$s.', "\x02", $opts->[3], $opts->[2]));
}

sub acl_add_user {
    my ($sophia, $target, $opts) = @_;
    $sophia = ${$sophia};

    $opts->[2] = lc $opts->[2];

    if (sophia_user_exists($opts->[2])) {
        $sophia->yield(privmsg => $target => sprintf('User %1$s%2$s%1$s already exists.', "\x02", $opts->[2]));
        return;
    }

    sophia_user_add($opts->[2], $opts->[3]);
    $sophia->yield(privmsg => $target => sprintf('User %1$s%2$s%1$s added.', "\x02", $opts->[2]));
}

1;
