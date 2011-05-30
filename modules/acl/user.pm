use strict;
use warnings;
use feature 'switch';

sophia_module_add('acl.user', '1.0', \&init_acl_user, \&deinit_acl_user);

sub init_acl_user {
    sophia_command_add('acl.user', \&acl_user, 'Gets the INFO of a USER.', '', SOPHIA_ACL_FOUNDER);
    sophia_event_privmsg_hook('acl.user', \&acl_user, 'Gets the INFO of a USER.', '', SOPHIA_ACL_FOUNDER);

    return 1;
}

sub deinit_acl_user {
    delete_sub 'init_acl_user';
    delete_sub 'acl_user';
    sophia_command_del 'acl.user';
    sophia_event_privmsg_dehook 'acl.user';
    delete_sub 'deinit_acl_user';
}

sub acl_user {
    my ($args, $target) = @_;
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    $target //= $where->[0];

    my @opts = split /\s+/, $content;
    return unless scalar(@opts) == 3 && uc $opts[1] eq 'INFO';

    $opts[2] = lc $opts[2];

    my $sophia = ${$args->[HEAP]->{sophia}};
    unless (sophia_user_exists($opts[2])) {
        $sophia->yield(privmsg => $target => sprintf('User %1$s%2$s%1$s does not exist.', "\x02", $opts[2]));
        return;
    }

    my $users = &sophia_acl_users;
    my $user = $users->{$opts[2]};

    $sophia->yield(privmsg => $target => sprintf('User %1$s%2$s%1$s has flags (%1$s%3$s%1$s).', "\x02", $opts[2], sophia_acl_bits2flags($user->{FLAGS})));

    my $count = 0;
    my $output = sprintf('%1$sHostmasks%1$s:', "\x02");

    HOSTMASK: for (keys %{$user->{HOSTMASKS}}) {
        if ($count + length > 350) {
            $sophia->yield(privmsg => $target => $output);
            ($count, $output) = (0, '');
        }

        $output .= sprintf(' %s', $_);
        $count += length;
    }
    
    $sophia->yield(privmsg => $target => $output) unless $count == 0;

    ($count, $output) = (0, sprintf('%1$sGroups%1$s:', "\x02"));

    GROUP: for (keys %{$user->{GROUPS}}) {
        if ($count + length > 350) {
            $sophia->yield(privmsg => $target => $output);
            ($count, $output) = (0, '');
        }

        $output .= sprintf(' %s', $_);
        $count += length;
    }

    $sophia->yield(privmsg => $target => $output) unless $count == 0;

    ($count, $output) = (0, sprintf('%1$sChannels%1$s:', "\x02"));

    CHANNEL: for (keys %{$user->{CHANNELS}}) {
        if ($count + length > 350) {
            $sophia->yield(privmsg => $target =>$output);
            ($count, $output) = (0, '');
        }

        $output .= sprintf('%s%s: %s', ($output eq '' ? '' : ' | '), $_, sophia_acl_bits2flags($user->{CHANNELS}{$_}));
        $count += length;
    }

    $sophia->yield(privmsg => $target => $output) unless $count == 0;
}

1;
