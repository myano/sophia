use strict;
use warnings;
use feature 'switch';

my $sophia_acl_db = $sophia::CONFIGURATIONS{ACL_DB};

sub sophia_acl_db_load {
    return unless -e $sophia_acl_db;
    
    open my $fh, '<', $sophia_acl_db or sophia_log('sophia', "Error opening db file: $!") and return;
    &sophia_acl_clear;
    sophia_reload_founder();

    my @parts;

    LINE: while (<$fh>) {
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

    close $fh;
}

sub sophia_acl_db_save {
    open my $fh, '>', $sophia_acl_db or sophia_log('sophia', 'Unable to open ACL DB file for writing.');

    my ($SOPHIA_ACL_GROUPS, $SOPHIA_ACL_USERS, $SOPHIA_ACL_HOST2UID);

    $SOPHIA_ACL_GROUPS = &sophia_acl_groups;
    $SOPHIA_ACL_USERS  = &sophia_acl_users;
    $SOPHIA_ACL_HOST2UID = &sophia_acl_host2uid;

    for (keys %{$SOPHIA_ACL_GROUPS}) {
        print {$fh} sprintf('SG S %s %s%s', $_, sophia_acl_bits2flags($SOPHIA_ACL_GROUPS->{$_}{FLAGS}), "\n");

        for my $chan (keys %{$SOPHIA_ACL_GROUPS->{$_}{CHANNELS}}) {
            print {$fh} sprintf('SG C %s %s %s%s', $chan, $_, sophia_acl_bits2flags($SOPHIA_ACL_GROUPS->{$_}{CHANNELS}{$chan}), "\n");
        }
    }

    USER: for (keys %{$SOPHIA_ACL_USERS}) {
        next USER if $SOPHIA_ACL_USERS->{$_}{IS_FOUNDER};

        print {$fh} sprintf('SU S %s %s%s', $_, sophia_acl_bits2flags($SOPHIA_ACL_USERS->{$_}{FLAGS}), "\n");

        for my $group (keys %{$SOPHIA_ACL_USERS->{$_}{GROUPS}}) {
            print {$fh} sprintf('SU G %s %s%s', $_, $group, "\n");
        }

        for my $chan (keys %{$SOPHIA_ACL_USERS->{$_}{CHANNELS}}) {
            print {$fh} sprintf('SU C %s %s %s%s', $chan, $_, sophia_acl_bits2flags($SOPHIA_ACL_USERS->{$_}{CHANNELS}{$chan}), "\n");
        }
    }

    for (keys %{$SOPHIA_ACL_HOST2UID}) {
        print {$fh} sprintf('SU I %s %s%s', $SOPHIA_ACL_HOST2UID->{$_}, $_, "\n");
    }

    close $fh;
}

1;
