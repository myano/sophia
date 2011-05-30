use strict;
use warnings;
use feature 'switch';

sophia_module_add('acl.del', '1.0', \&init_acl_del, \&deinit_acl_del);

sub init_acl_del {
   sophia_command_add('acl.del', \&acl_del, 'Deletes an entry to sophia\'s ACL.', '', SOPHIA_ACL_FOUNDER);
   sophia_event_privmsg_hook('acl.del', \&acl_del, 'Deletes an entry to sophia\'s ACL.', '', SOPHIA_ACL_FOUNDER);

   return 1;
}

sub deinit_acl_del {
    delete_sub 'init_acl_del';
    delete_sub 'acl_del';
    delete_sub 'acl_del_group';
    delete_sub 'acl_del_host';
    delete_sub 'acl_del_user';
    sophia_command_del 'acl.del';
    sophia_event_privmsg_dehook 'acl.del';
    delete_sub 'deinit_acl_del';
}

sub acl_del {
    my ($args, $target) = @_;
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    $target //= $where->[0];

    my @opts = split /\s+/, $content;
    my $len = scalar @opts;

    my $opt = $opts[1];
    $opt = uc $opt;

    my $sophia = $args->[HEAP]->{sophia};

    given ($opt) {
        when ('GROUP') { 
            return unless $len == 3;
            acl_del_group($sophia, $target, \@opts);
        }
        when ('HOST')  { 
            return unless $len == 4;
            acl_del_host($sophia, $target, \@opts);
        }
        when ('USER')  { 
            return unless $len == 3;
            acl_del_user($sophia, $target, \@opts);
        }
    }
}

sub acl_del_group {
    my ($sophia, $target, $opts) = @_;
    $sophia = ${$sophia};

    $opts->[2] = lc $opts->[2];

    if (!sophia_group_exists($opts->[2])) {
        $sophia->yield(privmsg => $target => sprintf('Group %1$s%2$s%1$s does not exist.', "\x02", $opts->[2]));
        return;
    }

    sophia_group_del($opts->[2]);
    $sophia->yield(privmsg => $target => sprintf('Group %1$s%2$s%1$s deleted.', "\x02", $opts->[2]));
}

sub acl_del_host {
    my ($sophia, $target, $opts) = @_;
    $sophia = ${$sophia};

    ($opts->[2], $opts->[3]) = (lc $opts->[2], $opts->[3]);

    if (!sophia_user_exists($opts->[2])) {
        $sophia->yield(privmsg => $target => sprintf('User %1$s%2$s%1$s does not exist.', "\x02", $opts->[2]));
        return;
    }

    sophia_userhost_del($opts->[2], $opts->[3]);
    $sophia->yield(privmsg => $target => sprintf('Host %1$s%2$s%1$s deleted from user %1$s%2$s%1$s.', "\x02", $opts->[3], $opts->[2]));
}

sub acl_del_user {
    my ($sophia, $target, $opts) = @_;
    $sophia = ${$sophia};

    $opts->[2] = lc $opts->[2];

    if (!sophia_user_exists($opts->[2])) {
        $sophia->yield(privmsg => $target => sprintf('User %1$s%2$s%1$s does not exist.', "\x02", $opts->[2]));
        return;
    }

    sophia_user_del($opts->[2]);
    $sophia->yield(privmsg => $target => sprintf('User %1$s%2$s%1$s deleted.', "\x02", $opts->[2]));
}

1;
