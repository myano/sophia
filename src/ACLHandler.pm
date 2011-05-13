use strict;
use warnings;
use feature 'switch';

my $sophia_acl_db = $sophia::CONFIGURATIONS{ACL_DB};

sub acl_db_load {
    return unless -e $sophia_acl_db;
    
    open DB, $sophia_acl_db or sophia_log('sophia', "Error opening db file: $!");
    &sophia_acl_clear;

    my @parts;

    LINE: while (<DB>) {
        chomp;
        @parts = split / /;
        
        given ($parts[0]) {
            when ('SG') {
                given ($parts[1]) {
                    when ('S') { sophia_group_add($parts[2], $parts[3]); }
                    when ('C') { sophia_group_chanflags($parts[3], $parts[2], $parts[4]); }
                }
            }
            when ('SU') {
                given ($parts[1]) {
                    when ('S') { sophia_user_add($parts[2], $parts[3]); }
                    when ('I') { sophia_map_host2uid($parts[2], $parts[3]); }

                    when ('G') { sophia_group_user_add($parts[2], $parts[3]); }
                    when ('C') { sophia_user_chanflags($parts[3], $parts[2], $parts[4]) }
                }
            }
        }
    }

    close DB;
}

sub acl_db_save {
    open DB, "> $sophia_acl_db" or sophia_log('sophia', 'Unable to open ACL DB file for writing.');

    my ($SOPHIA_ACL_GROUPS, $SOPHIA_ACL_USERS, $SOPHIA_ACL_HOST2UID);

    $SOPHIA_ACL_GROUPS = &sophia_acl_groups;
    $SOPHIA_ACL_USERS  = &sophia_acl_users;
    $SOPHIA_ACL_HOST2UID = &sophia_host2uid;

    for (keys %{$SOPHIA_ACL_GROUPS}) {
        print DB sprintf('SG S %s %s', $_, sophia_acl_bits2flags($SOPHIA_ACL_GROUPS->{$_}{FLAGS}));

        for my $chan (keys %{$SOPHIA_ACL_GROUPS->{$_}{CHANNELS}}) {
            print DB sprintf('SG C %s %s %s', $chan, $_, sophia_acl_bits2flags($SOPHIA_ACL_GROUPS->{$_}{CHANNELS}{$chan}));
        }
    }

    for (keys %{$SOPHIA_ACL_USERS}) {
        print DB sprintf('SU S %s %s', $_, sophia_acl_bits2flags($SOPHIA_ACL_USERS->{$_}{FLAGS}));

        for my $group (keys %{$SOPHIA_ACL_USERS->{$_}{GROUPS}}) {
            print DB sprintf('SU G %s %s', $_, $group);
        }

        for my $chan (keys %{$SOPHIA_ACL_USERS->{$_}{CHANNELS}}) {
            print DB sprintf('SU C %s %s %s', $chan, $_, sophia_acl_bits2flags($SOPHIA_ACL_USERS->{$_}{CHANNELS}{$chan}));
        }
    }

    for (keys %{$SOPHIA_ACL_HOST2UID}) {
        print DB sprintf('SU I %s %s', $SOPHIA_ACL_HOST2UID->{$_}, $_);
    }

    close DB;
}

1;
