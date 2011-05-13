use strict;
use warnings;

use constant SOPHIA_ACL_NONE            => 0x0;

use constant SOPHIA_ACL_VOICE           => 0x0001;
use constant SOPHIA_ACL_AUTOVOICE       => 0x0002;
use constant SOPHIA_ACL_OP              => 0x0004;
use constant SOPHIA_ACL_AUTOOP          => 0x0008;

use constant SOPHIA_ACL_CHANGETOPIC     => 0x0010;
use constant SOPHIA_ACL_USEGRANT        => 0x0020;
use constant SOPHIA_ACL_BANNED          => 0x0040;

use constant SOPHIA_ACL_FRIEND          => 0x0100;
use constant SOPHIA_ACL_ADMIN           => 0x0200;
use constant SOPHIA_ACL_FOUNDER         => 0x0400;

use constant SOPHIA_FRIEND              => (SOPHIA_ACL_VOICE | SOPHIA_ACL_OP | SOPHIA_ACL_CHANGETOPIC | SOPHIA_ACL_USEGRANT | SOPHIA_ACL_FRIEND);
use constant SOPHIA_ADMIN               => (SOPHIA_ACL_VOICE | SOPHIA_ACL_OP | SOPHIA_ACL_CHANGETOPIC | SOPHIA_ACL_USEGRANT | SOPHIA_ACL_FRIEND | SOPHIA_ACL_ADMIN);
use constant SOPHIA_FOUNDER             => (SOPHIA_ACL_VOICE | SOPHIA_ACL_OP | SOPHIA_ACL_CHANGETOPIC | SOPHIA_ACL_USEGRANT | SOPHIA_ACL_FRIEND | SOPHIA_ACL_ADMIN | SOPHIA_ACL_FOUNDER);

my %SOPHIA_ACL_FLAGS = (
    b   => SOPHIA_ACL_BANNED,
    v   => SOPHIA_ACL_VOICE,
    V   => SOPHIA_ACL_AUTOVOICE,
    o   => SOPHIA_ACL_OP,
    O   => SOPHIA_ACL_AUTOOP,
    t   => SOPHIA_ACL_CHANGETOPIC,
    s   => SOPHIA_ACL_USEGRANT,
    f   => SOPHIA_ACL_FRIEND,
    A   => SOPHIA_ACL_ADMIN,
    F   => SOPHIA_ACL_FOUNDER,
);


my (%SOPHIA_ACL_GROUPS, %SOPHIA_ACL_USERS, %SOPHIA_ACL_HOST2UID);

sub sophia_acl_groups {
    return \%SOPHIA_ACL_GROUPS;
}

sub sophia_acl_users {
    return \%SOPHIA_ACL_USERS;
}

sub sophia_acl_host2uid {
    return \%SOPHIA_ACL_HOST2UID;
}

sub sophia_group_add {
    my ($group_name, $flags) = @_;
    $group_name = lc $group_name;
    return 0 if sophia_group_exists($group_name);

    %{$SOPHIA_ACL_GROUPS{$group_name}} = (
        FLAGS       => SOPHIA_ACL_NONE,
        USERS       => {},
        CHANNELS    => {},
    );

    sophia_group_flags($group_name, $flags);

    return 1;
}

sub sophia_group_flags {
    my ($group_name, $flags) = @_;
    $group_name = lc $group_name;
    return 0 unless sophia_group_exists($group_name) && $flags;

    my @flaglist = split //, $flags;
    my $dir = undef;

    FLAG : for (@flaglist) {
        $dir = 1 if $_ eq '+';
        $dir = 0 if $_ eq '-';
        
        next FLAG if !defined $dir || !defined $SOPHIA_ACL_FLAGS{$_};
        $SOPHIA_ACL_GROUPS{$group_name}{FLAGS} |= $SOPHIA_ACL_FLAGS{$_} if $dir;
        $SOPHIA_ACL_GROUPS{$group_name}{FLAGS} &= ~$SOPHIA_ACL_FLAGS{$_} if !$dir;
    }

    return 1;
}

sub sophia_group_chanflags {
    my ($group_name, $chan, $flags) = @_;
    ($group_name, $chan) = (lc $group_name, lc $chan);
    return 0 unless sophia_group_exists($group_name) && $chan && $flags;

    my @flaglist = split //, $flags;
    my $dir = undef;

    $SOPHIA_ACL_GROUPS{$group_name}{CHANNELS}{$chan} = SOPHIA_ACL_NONE unless exists($SOPHIA_ACL_GROUPS{$group_name}{CHANNELS}{$chan});
    FLAG : for (@flaglist) {
        $dir = 1 if $_ eq '+';
        $dir = 0 if $_ eq '-';

        next FLAG if !defined $dir || !defined $SOPHIA_ACL_FLAGS{$_};
        $SOPHIA_ACL_GROUPS{$group_name}{CHANNELS}{$chan} |= $SOPHIA_ACL_FLAGS{$_} if $dir;
        $SOPHIA_ACL_GROUPS{$group_name}{CHANNELS}{$chan} &= ~$SOPHIA_ACL_FLAGS{$_} if !$dir;
    }

    return 1;
}

sub sophia_group_rename {
    my ($old_name, $new_name) = @_;
    ($old_name, $new_name) = (lc $old_name, $new_name);
    return 0 unless sophia_group_exists($old_name) && $new_name;
    return -1 if sophia_group_exists($new_name);
    
    %{$SOPHIA_ACL_GROUPS{$new_name}} = %{$SOPHIA_ACL_GROUPS{$old_name}};
    sophia_group_del $old_name;
    return 1;
}

sub sophia_group_del {
    my $group_name = $_[0];
    $group_name = lc $group_name;
    return 0 unless sophia_group_exists($group_name);

    delete $SOPHIA_ACL_GROUPS{$group_name};
    return 1;
}

sub sophia_user_add {
    my ($uid, $flags) = @_;
    $uid = lc $uid;
    return 0 if sophia_user_exists($uid);

    %{$SOPHIA_ACL_USERS{$uid}} = (
        FLAGS       => SOPHIA_ACL_NONE,
        GROUPS      => {},
        HOSTMASKS   => {},
        CHANNELS    => {},
    );

    sophia_user_flags($uid, $flags);

    return 1;
}

sub sophia_get_host_perms {
    my ($host, $chan) = @_;
    ($host, $chan) = (lc $host, lc $chan);
    my $uid = sophia_uid_from_host($host);
    return SOPHIA_ACL_NONE unless $uid;
    return sophia_get_user_perms($uid, $chan);
}

sub sophia_get_user_perms {
    my ($uid, $chan) = @_;
    ($uid, $chan) = (lc $uid, lc $chan);
    return SOPHIA_ACL_NONE unless sophia_user_exists($uid);

    my $perms = $SOPHIA_ACL_USERS{$uid}{FLAGS};
    $perms |= $SOPHIA_ACL_GROUPS{$_}{FLAGS} for keys %{$SOPHIA_ACL_USERS{$uid}{GROUPS}};

    return $perms unless $chan && $SOPHIA_ACL_USERS{$uid}{CHANNELS}{$chan};

    $perms |= $SOPHIA_ACL_USERS{$uid}{CHANNELS}{$chan};
    $perms |= $SOPHIA_ACL_GROUPS{$_}{CHANNELS}{$chan} for keys %{$SOPHIA_ACL_USERS{$uid}{GROUPS}};

    return $perms;
}

sub sophia_user_chanflags {
    my ($uid, $chan, $flags) = @_;
    ($uid, $chan) = (lc $uid, lc $chan);
    return 0 unless sophia_user_exists($uid) && $chan && $flags;

    my @flaglist = split //, $flags;
    my $dir = undef;

    $SOPHIA_ACL_USERS{$uid}{CHANNELS}{$chan} = SOPHIA_ACL_NONE unless exists($SOPHIA_ACL_USERS{$uid}{CHANNELS}{$chan});
    FLAG : for (@flaglist) {
        $dir = 1 if $_ eq '+';
        $dir = 0 if $_ eq '-';

        next FLAG if !defined $dir || !defined $SOPHIA_ACL_FLAGS{$_};
        $SOPHIA_ACL_USERS{$uid}{CHANNELS}{$chan} |= $SOPHIA_ACL_FLAGS{$_} if $dir;
        $SOPHIA_ACL_USERS{$uid}{CHANNELS}{$chan} &= ~$SOPHIA_ACL_FLAGS{$_} if !$dir;
    }

    return 1;
}

sub sophia_user_flags {
    my ($uid, $flags) = @_;
    $uid = lc $uid;
    return 0 unless sophia_user_exists($uid) && $flags;

    my @flaglist = split //, $flags;
    my $dir = undef;

    FLAG : for (@flaglist) {
        $dir = 1 if $_ eq '+';
        $dir = 0 if $_ eq '-';

        next FLAG if !defined $dir || !defined $SOPHIA_ACL_FLAGS{$_};
        $SOPHIA_ACL_USERS{$uid}{FLAGS} |= $SOPHIA_ACL_FLAGS{$_} if $dir;
        $SOPHIA_ACL_USERS{$uid}{FLAGS} &= ~$SOPHIA_ACL_FLAGS{$_} if !$dir;
    }

    return 1;
}

sub sophia_user_group_add {
    my ($uid, $group_name) = @_;
    ($uid, $group_name) = (lc $uid, lc $group_name);
    return 0 unless sophia_user_exists($uid) && sophia_group_exists($group_name);

    $SOPHIA_ACL_USERS{$uid}{GROUPS}{$group_name} = 1;
    $SOPHIA_ACL_GROUPS{$group_name}{USERS}{$uid} = 1;
    return 1;
}

sub sophia_user_group_del {
    my ($uid, $group_name) = @_;
    ($uid, $group_name) = (lc $uid, lc $group_name);
    return 0 unless sophia_user_exists($uid) && sophia_group_exists($group_name);

    delete $SOPHIA_ACL_USERS{$uid}{GROUPS}{$group_name};
    delete $SOPHIA_ACL_GROUPS{$group_name}{USERS}{$uid};
    return 1;
}

sub sophia_userhost_add {
    my ($uid, $host) = @_;
    ($uid, $host) = (lc $uid, lc $host);
    return 0 unless sophia_user_exists($uid) && $host;

    $SOPHIA_ACL_USERS{$uid}{HOSTMASKS}{$host} = 1;
    sophia_map_host2uid($uid, $host);

    return 1;
}

sub sophia_userhost_del {
    my ($uid, $host) = @_;
    ($uid, $host) = (lc $uid, lc $host);
    return 0 unless sophia_user_exists($uid) && $host;

    delete $SOPHIA_ACL_USERS{$uid}{HOSTMASKS}{$host};
    sophia_unmap_host2uid($host);
    return 1;
}

sub sophia_user_del {
    my $uid = $_[0];
    $uid = lc $uid;
    return 0 unless sophia_user_exists($uid);

    sophia_unmap_host2uid $_ for keys %{$SOPHIA_ACL_USERS{$uid}{HOSTMASKS}};

    delete $SOPHIA_ACL_USERS{$uid};
    return 1;
}

sub sophia_uid_from_host {
    my $host = $_[0];
    $host = lc $host;
    return unless $host;

    my $hostmask;
    for (keys %SOPHIA_ACL_HOST2UID) {
        $hostmask = $_;
        $hostmask =~ s/\*/.*?/g;
        return $SOPHIA_ACL_HOST2UID{$_} if $host =~ /$hostmask/;
    }

    return;
}

sub sophia_map_host2uid {
    my ($uid, $host) = @_;
    ($uid, $host) = (lc $uid, lc $host);
    return 0 unless sophia_user_exists($uid) && $host;

    $SOPHIA_ACL_USERS{$uid}{HOSTMASKS}{$host} = 1;
    $SOPHIA_ACL_HOST2UID{$host} = $uid;
    return 1;
}

sub sophia_unmap_host2uid {
    my $host = $_[0];
    $host = lc $host;

    my $uid = $SOPHIA_ACL_HOST2UID{$host};
    delete $SOPHIA_ACL_USERS{$uid}{HOSTMASKS}{$host} if $uid;
    delete $SOPHIA_ACL_HOST2UID{$host};
}

sub sophia_group_exists {
    my $group_name = $_[0];
    $group_name = lc $group_name;
    return 0 unless $group_name;

    return exists $SOPHIA_ACL_GROUPS{$group_name};
}

sub sophia_user_exists {
    my $uid = $_[0];
    $uid = lc $uid;
    return 0 unless $uid;

    return exists $SOPHIA_ACL_USERS{$uid};
}

sub sophia_acl_bits2flags {
    my $bits = $_[0];
    my $flags = '';

    for (keys %SOPHIA_ACL_FLAGS) {
        $flags .= $_ if $bits & $SOPHIA_ACL_FLAGS{$_};
    }

    $flags = sprintf('+%s', $flags) if $flags;

    return $flags;
}

sub sophia_groups_clear {
    delete $SOPHIA_ACL_GROUPS{$_} for keys %SOPHIA_ACL_GROUPS;
}

sub sophia_users_clear {
    delete $SOPHIA_ACL_USERS{$_}  for keys %SOPHIA_ACL_USERS;
}

sub sophia_host2uid_clear {
    delete $SOPHIA_ACL_HOST2UID{$_}  for keys %SOPHIA_ACL_HOST2UID;
}

sub sophia_acl_clear {
    &sophia_groups_clear;
    &sophia_users_clear;
    &sophia_host2uid_clear;
}

1;
