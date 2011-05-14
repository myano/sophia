use strict;
use warnings;
use feature 'switch';

sophia_module_add('acl.group', '1.0', \&init_acl_group, \&deinit_acl_group);

sub init_acl_group {
    sophia_command_add('acl.group', \&acl_group, 'Gets the info of a group or a list of its members.', '');
    
    return 1;
}

sub deinit_acl_group {
    delete_sub 'init_acl_group';
    delete_sub 'acl_group';
    delete_sub 'acl_group_info';
    delete_sub 'acl_group_list';
    delete_sub 'acl_group_list_all';
    sophia_command_del 'acl.group';
    delete_sub 'deinit_acl_group';
}

sub acl_group {
    my $param = $_[0];
    my @args = @{$param};
    my ($who, $where, $content) = @args[ARG0 .. ARG2];

    my $perms = sophia_get_host_perms($who);
    return unless $perms & SOPHIA_ACL_FOUNDER;

    my @opts = split /\s+/, $content;
    return unless scalar(@opts) == 3;

    given ($opts[1]) {
        when ('INFO')   { acl_group_info($args[HEAP]->{sophia}, $where, \@opts); }
        when ('LIST')   { acl_group_list($args[HEAP]->{sophia}, $where, \@opts); }
    }
}

sub acl_group_info {
    my ($sophia, $where, $opts) = @_;
    my @opts = @{$opts};
    $sophia = ${$sophia};

    $opts[2] = lc $opts[2];

    unless (sophia_group_exists($opts[2])) {
        $sophia->yield(privmsg => $where->[0] => sprintf('Group %1$s%2$s%1$s does not exist.', "\x02", $opts[2]));
        return;
    }

    my $groups = &sophia_acl_groups;
    my $group = $groups->{$opts[2]};

    $sophia->yield(privmsg => $where->[0] => sprintf('Group %1$s%2$s%1$s has flags (%1$s%3$s%1$s) with %1$s%4$d%1$s members, and the following channel flags:', "\x02", $opts[2], $group->{FLAGS}, scalar(keys %{$group->{USERS}})));

    my $output = '';
    my $count = 0;
    CHANNEL: for (keys %{$group->{CHANNELS}}) {
        if ($count + length > 350) {
            $sophia->yield(privmsg => $where->[0] => $output);
            ($count, $output) = (0, '');
        }
        
        $output .= sprintf('%2$s%1$s%3$s%1$s: %4$s', "\x02", ($output eq '' ? '' : ' | '), $_, $group->{CHANNELS}{$_});
        $count += length;
    }

    $sophia->yield(privmsg => $where->[0] => $output) unless $output eq '';
}

sub acl_group_list {
    my ($sophia, $where, $opts) = @_;
    my @opts = @{$opts};

    if ($opts[2] eq '*') {
        acl_group_list_all($sophia, $where, $opts);
        return;
    }

    $sophia = ${$sophia};

    $opts[2] = lc $opts[2];

    unless (sophia_group_exists($opts[2])) {
        $sophia->yield(privmsg => $where->[0] => sprintf('Group %1$s%2$s%1$s does not exist.', "\x02", $opts[2]));
        return;
    }

    my $groups = &sophia_acl_groups;
    my $group = $groups->{$opts[2]};

    my $output = '';
    my $count = 0;

    $sophia->yield(privmsg => $where->[0] => sprintf('Group %1$s%2$s%1$s has %1$s%3$d%1$s members:', "\x02", $opts[2], scalar(keys %{$group->{USERS}})));

    USER: for (keys %{$group->{USERS}}) {
        if ($count + length > 350) {
            $sophia->yield(privmsg => $where->[0] => $output);
            ($count, $output) = (0, '');
        }

        $output .= sprintf('%s ', $_);
        $count += length;
    }

    $sophia->yield(privmsg => $where->[0] => $output) unless $output eq '';
}

sub acl_group_list_all {
    my ($sophia, $where, $opts) = @_;
    my @opts = @{$opts};
    $sophia = ${$sophia};

    my $groups = &sophia_acl_groups;

    my $output = '';
    my $count = 0;

    GROUP: for (keys %{$groups}) {
        if ($count + length > 350) {
            $sophia->yield(privmsg => $where->[0] => $output);
            ($count, $output) = (0, '');
        }

        $output .= sprintf('%2$s%1$s%3$s%1$s: %4$s', "\x02", ($output eq ''? '' : ' | '), $_, $groups->{$_}{FLAGS});
        $count += length;
    }

    $sophia->yield(privmsg => $where->[0] => $output) unless $output eq '';
}

1;