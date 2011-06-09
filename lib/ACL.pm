use strict;
use warnings;

use constant {
    SOPHIA_ACL_NONE                     => 0x0,
    SOPHIA_ACL_VOICE                    => 0x0001,
    SOPHIA_ACL_AUTOVOICE                => 0x0002,
    SOPHIA_ACL_OP                       => 0x0004,
    SOPHIA_ACL_AUTOOP                   => 0x0008,

    SOPHIA_ACL_CHANGETOPIC              => 0x0010,
    SOPHIA_ACL_USEGRANT                 => 0x0020,
    SOPHIA_ACL_BANNED                   => 0x0040,

    SOPHIA_ACL_FRIEND                   => 0x0100,
    SOPHIA_ACL_ADMIN                    => 0x0200,
    SOPHIA_ACL_FOUNDER                  => 0x0400,
};

use constant SOPHIA_FRIEND              => (SOPHIA_ACL_VOICE | SOPHIA_ACL_OP | SOPHIA_ACL_CHANGETOPIC | SOPHIA_ACL_USEGRANT | SOPHIA_ACL_FRIEND);
use constant SOPHIA_ADMIN               => (SOPHIA_FRIEND | SOPHIA_ACL_ADMIN);
use constant SOPHIA_FOUNDER             => (SOPHIA_ADMIN  | SOPHIA_ACL_FOUNDER);
use constant SOPHIA_ACL_ALL             => (SOPHIA_FOUNDER | SOPHIA_ACL_AUTOVOICE | SOPHIA_ACL_AUTOOP);

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

my %SOPHIA_ACL_MASTER = (
    UID         => '',
    HOSTMASK    => '',
    FLAGS       => sophia_acl_bits2flags(SOPHIA_ACL_ALL),
    FLAGBITS    => SOPHIA_ACL_ALL,
);

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
    return 0 if sophia_group_exists($group_name) || !$group_name;

    $group_name = lc $group_name;

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
    return 0 unless sophia_group_exists($group_name) && $flags;

    $group_name = lc $group_name;

    my @flaglist = split //, $flags;
    my $dir = undef;

    FLAG : for (@flaglist) {
        $dir = 1 if $_ eq '+';
        $dir = 0 if $_ eq '-';
        
        next FLAG if !defined $dir;

        if ($_ eq '*') {
            $SOPHIA_ACL_GROUPS{$group_name}{FLAGS} |= SOPHIA_ADMIN if $dir;
            $SOPHIA_ACL_GROUPS{$group_name}{FLAGS} &= ~SOPHIA_ADMIN if !$dir;
            next FLAG;
        }
        
        next FLAG if !defined $SOPHIA_ACL_FLAGS{$_};
        $SOPHIA_ACL_GROUPS{$group_name}{FLAGS} |= $SOPHIA_ACL_FLAGS{$_} if $dir;
        $SOPHIA_ACL_GROUPS{$group_name}{FLAGS} &= ~$SOPHIA_ACL_FLAGS{$_} if !$dir;
    }

    return 1;
}

sub sophia_group_chanflags {
    my ($group_name, $chan, $flags) = @_;
    return 0 unless sophia_group_exists($group_name) && $chan && $flags;

    ($group_name, $chan) = (lc $group_name, lc $chan);

    my @flaglist = split //, $flags;
    my $dir = undef;

    $SOPHIA_ACL_GROUPS{$group_name}{CHANNELS}{$chan} = SOPHIA_ACL_NONE unless exists($SOPHIA_ACL_GROUPS{$group_name}{CHANNELS}{$chan});
    FLAG : for (@flaglist) {
        $dir = 1 if $_ eq '+';
        $dir = 0 if $_ eq '-';

        next FLAG if !defined $dir;

        if ($_ eq '*') {
            $SOPHIA_ACL_GROUPS{$group_name}{CHANNELS}{$chan} |= SOPHIA_ADMIN if $dir;
            $SOPHIA_ACL_GROUPS{$group_name}{CHANNELS}{$chan} &= ~SOPHIA_ADMIN if !$dir;
            next FLAG;
        }
        
        next FLAG if !defined $SOPHIA_ACL_FLAGS{$_};
        $SOPHIA_ACL_GROUPS{$group_name}{CHANNELS}{$chan} |= $SOPHIA_ACL_FLAGS{$_} if $dir;
        $SOPHIA_ACL_GROUPS{$group_name}{CHANNELS}{$chan} &= ~$SOPHIA_ACL_FLAGS{$_} if !$dir;
    }

    return 1;
}

sub sophia_group_rename {
    my ($old_name, $new_name) = @_;
    return 0 unless sophia_group_exists($old_name) && $new_name;
    return -1 if sophia_group_exists($new_name);

    ($old_name, $new_name) = (lc $old_name, $new_name);
    
    %{$SOPHIA_ACL_GROUPS{$new_name}} = %{$SOPHIA_ACL_GROUPS{$old_name}};
    sophia_group_del $old_name;
    return 1;
}

sub sophia_group_del {
    my $group_name = $_[0];
    return 0 unless sophia_group_exists($group_name);

    $group_name = lc $group_name;

    delete $SOPHIA_ACL_GROUPS{$group_name};
    return 1;
}

sub sophia_user_add {
    my ($uid, $flags) = @_;
    return 0 if sophia_user_exists($uid) || sophia_is_master($uid);

    $uid = lc $uid;

    %{$SOPHIA_ACL_USERS{$uid}} = (
        FLAGS       => SOPHIA_ACL_NONE,
        GROUPS      => {},
        HOSTMASKS   => {},
        CHANNELS    => {},
        IS_MASTER   => 0,
    );

    sophia_user_flags($uid, $flags);

    return 1;
}

sub sophia_get_host_perms {
    my ($host, $chan) = @_;
    return unless $host;

    $host = lc $host;
    my $uid = sophia_uid_from_host($host);
    return SOPHIA_ACL_NONE unless $uid;
    return sophia_get_user_perms($uid, $chan);
}

sub sophia_get_user_perms {
    my ($uid, $chan) = @_;
    return SOPHIA_ACL_NONE unless sophia_user_exists($uid);

    $uid = lc $uid;

    return $SOPHIA_ACL_MASTER{FLAGBITS} if sophia_is_master($uid);

    my $perms = $SOPHIA_ACL_USERS{$uid}{FLAGS};
    $perms |= $SOPHIA_ACL_GROUPS{$_}{FLAGS} for keys %{$SOPHIA_ACL_USERS{$uid}{GROUPS}};

    return $perms unless $chan && $SOPHIA_ACL_USERS{$uid}{CHANNELS}{$chan};

    $chan = lc $chan;

    $perms |= $SOPHIA_ACL_USERS{$uid}{CHANNELS}{$chan};
    $perms |= $SOPHIA_ACL_GROUPS{$_}{CHANNELS}{$chan} for keys %{$SOPHIA_ACL_USERS{$uid}{GROUPS}};

    return $perms;
}

sub sophia_user_chanflags {
    my ($uid, $chan, $flags) = @_;
    return 0 unless sophia_user_exists($uid) && !sophia_is_master($uid) && $chan && $flags;

    ($uid, $chan) = (lc $uid, lc $chan);
    my @flaglist = split //, $flags;
    my $dir = undef;

    $SOPHIA_ACL_USERS{$uid}{CHANNELS}{$chan} = SOPHIA_ACL_NONE unless exists($SOPHIA_ACL_USERS{$uid}{CHANNELS}{$chan});
    FLAG : for (@flaglist) {
        $dir = 1 if $_ eq '+';
        $dir = 0 if $_ eq '-';

        next FLAG if !defined $dir;
        
        if ($_ eq '*') {
            $SOPHIA_ACL_USERS{$uid}{CHANNELS}{$chan} |= SOPHIA_ADMIN if $dir;
            $SOPHIA_ACL_USERS{$uid}{CHANNELS}{$chan} &= ~SOPHIA_ADMIN if !$dir;
            next FLAG;
        }

        next FLAG if !defined $SOPHIA_ACL_FLAGS{$_};
        $SOPHIA_ACL_USERS{$uid}{CHANNELS}{$chan} |= $SOPHIA_ACL_FLAGS{$_} if $dir;
        $SOPHIA_ACL_USERS{$uid}{CHANNELS}{$chan} &= ~$SOPHIA_ACL_FLAGS{$_} if !$dir;
    }

    return 1;
}

sub sophia_user_flags {
    my ($uid, $flags) = @_;
    return 0 unless sophia_user_exists($uid) && !sophia_is_master($uid) && $flags;

    $uid = lc $uid;

    my @flaglist = split //, $flags;
    my $dir = undef;

    FLAG : for (@flaglist) {
        $dir = 1 if $_ eq '+';
        $dir = 0 if $_ eq '-';

        next FLAG if !defined $dir;

        if ($_ eq '*') {
            $SOPHIA_ACL_USERS{$uid}{FLAGS} |= SOPHIA_ADMIN if $dir;
            $SOPHIA_ACL_USERS{$uid}{FLAGS} &= ~SOPHIA_ADMIN if !$dir;
            next FLAG;
        }
        
        next FLAG if !defined $SOPHIA_ACL_FLAGS{$_};
        $SOPHIA_ACL_USERS{$uid}{FLAGS} |= $SOPHIA_ACL_FLAGS{$_} if $dir;
        $SOPHIA_ACL_USERS{$uid}{FLAGS} &= ~$SOPHIA_ACL_FLAGS{$_} if !$dir;
    }

    return 1;
}

sub sophia_user_group_add {
    my ($uid, $group_name) = @_;
    return 0 unless sophia_user_exists($uid) && sophia_group_exists($group_name);

    ($uid, $group_name) = (lc $uid, lc $group_name);

    $SOPHIA_ACL_USERS{$uid}{GROUPS}{$group_name} = 1;
    $SOPHIA_ACL_GROUPS{$group_name}{USERS}{$uid} = 1;
    return 1;
}

sub sophia_user_group_del {
    my ($uid, $group_name) = @_;
    return 0 unless sophia_user_exists($uid) && sophia_group_exists($group_name);

    ($uid, $group_name) = (lc $uid, lc $group_name);

    delete $SOPHIA_ACL_USERS{$uid}{GROUPS}{$group_name};
    delete $SOPHIA_ACL_GROUPS{$group_name}{USERS}{$uid};
    return 1;
}

sub sophia_userhost_add {
    my ($uid, $host) = @_;
    return 0 unless sophia_user_exists($uid) && $host;

    ($uid, $host) = (lc $uid, lc $host);

    $SOPHIA_ACL_USERS{$uid}{HOSTMASKS}{$host} = 1;
    sophia_map_host2uid($uid, $host);

    return 1;
}

sub sophia_userhost_del {
    my ($uid, $host) = @_;
    return 0 unless sophia_user_exists($uid) && $host;
    return 0 if sophia_is_master($uid) && $host eq $SOPHIA_ACL_MASTER{HOSTMASK};

    ($uid, $host) = (lc $uid, lc $host);

    delete $SOPHIA_ACL_USERS{$uid}{HOSTMASKS}{$host};
    sophia_unmap_host2uid($host);
    return 1;
}

sub sophia_user_del {
    my $uid = $_[0];
    return 0 unless sophia_user_exists($uid) && !sophia_is_master($uid);

    $uid = lc $uid;

    sophia_unmap_host2uid($_) for keys %{$SOPHIA_ACL_USERS{$uid}{HOSTMASKS}};

    delete $SOPHIA_ACL_USERS{$uid};
    return 1;
}

sub sophia_set_master {
    my ($uid, $host) = @_;
    return unless $uid && $host;

    ($uid, $host) = (lc $uid, lc $host);

    # remove old master
    $SOPHIA_ACL_USERS{$SOPHIA_ACL_MASTER{UID}}{IS_MASTER} = 0 if $SOPHIA_ACL_MASTER{UID};
    sophia_unmap_host2uid($SOPHIA_ACL_MASTER{HOSTMASK});

    # add/set new master
    $SOPHIA_ACL_USERS{$uid}{IS_MASTER} = 1;
    sophia_map_host2uid($uid, $host);

    $SOPHIA_ACL_MASTER{UID} = $uid;
    $SOPHIA_ACL_MASTER{HOSTMASK} = $host;
    return 1;
}

sub sophia_has_master {
    return defined $SOPHIA_ACL_MASTER{UID};
}

sub sophia_is_master {
    my $uid = $_[0];
    $uid = lc $uid;
    return $uid eq $SOPHIA_ACL_MASTER{UID};
}

sub sophia_get_master {
    return \%SOPHIA_ACL_MASTER;
}

sub sophia_reload_master {
    return if $SOPHIA_ACL_MASTER{UID} eq '';

    my $uid = $SOPHIA_ACL_MASTER{UID};
    $SOPHIA_ACL_USERS{$uid}{FLAGS} = $SOPHIA_ACL_MASTER{FLAGBITS};
    $SOPHIA_ACL_USERS{$uid}{IS_MASTER} = 1;
    sophia_map_host2uid($uid, $SOPHIA_ACL_MASTER{HOSTMASK});
}

sub sophia_uid_from_host {
    my $host = $_[0];
    return unless $host;

    my $hostmask;
    for (keys %SOPHIA_ACL_HOST2UID) {
        $hostmask = $_;
        $hostmask =~ s/\./\\\./gxsm;
        $hostmask =~ s/\?/\./gxsm;
        $hostmask =~ s/\*/\.\*/gxsm;
        $hostmask =~ s/\//\\\//gxsm;
        return $SOPHIA_ACL_HOST2UID{$_} if $host =~ /\A$hostmask\z/xsmi;
    }

    return;
}

sub sophia_map_host2uid {
    my ($uid, $host) = @_;
    return 0 unless sophia_user_exists($uid) && $host;

    ($uid, $host) = (lc $uid, lc $host);

    $SOPHIA_ACL_USERS{$uid}{HOSTMASKS}{$host} = 1;
    $SOPHIA_ACL_HOST2UID{$host} = $uid;
    return 1;
}

sub sophia_unmap_host2uid {
    my $host = $_[0];
    return 0 unless $host;

    $host = lc $host;

    my $uid = $SOPHIA_ACL_HOST2UID{$host};
    delete $SOPHIA_ACL_USERS{$uid}{HOSTMASKS}{$host} if $uid;
    delete $SOPHIA_ACL_HOST2UID{$host};
    return 1;
}

sub sophia_group_exists {
    my $group_name = $_[0];
    return 0 unless $group_name;

    $group_name = lc $group_name;

    return exists $SOPHIA_ACL_GROUPS{$group_name};
}

sub sophia_user_exists {
    my $uid = $_[0];
    return 0 unless $uid;

    $uid = lc $uid;

    return exists $SOPHIA_ACL_USERS{$uid};
}

sub sophia_acl_bits2flags {
    my $bits = $_[0];
    my $flags = '';

    # no bits? do nothing
    return $flags if !$bits;

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
