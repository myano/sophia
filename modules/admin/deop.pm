use strict;
use warnings;

sophia_module_add('admin.deop', '2.0', \&init_admin_deop, \&deinit_admin_deop);

sub init_admin_deop {
    sophia_global_command_add('deop', \&admin_deop, 'Deops the user/hostmask.', '', SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP);
    sophia_event_privmsg_hook('sophia.deop', \&admin_deop, 'Deops the user/hostmask.', '', SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP);

    return 1;
}

sub deinit_admin_deop {
    delete_sub 'init_admin_deop';
    delete_sub 'admin_deop';
    sophia_global_command_del 'deop';
    sophia_event_privmsg_dehook 'sophia.deop';
    delete_sub 'deinit_admin_deop';
}

sub admin_deop {
    my ($args, $target) = @_;
    my ($who, $where, $content) = ($args->[ARG0], $args->[ARG1], $args->[ARG2]);
    my $target_chan = $where->[0];

    my @parts = split /\s+/, $content;

    # the first arg in @parts will be the command: !deop, so toss it out.
    shift @parts;

    # if this command is not ran in a channel and a channel is not provided as the first arg, do nothing
    return if !$parts[0] && $target;

    # if this command is not ran in a channel, store the target chan
    $target_chan = $parts[0] and shift @parts if $target;

    my $sophia = ${$args->[HEAP]->{sophia}};

    # if there are no params, deop the caller
    if (!$parts[0]) {
        $sophia->yield( mode => $target_chan => '-o' => substr $who, 0, index($who, '!') );
        return;
    }

    # deop the list of users
    $sophia->yield( mode => $target_chan => sprintf('-%s', 'o' x ($#parts + 1)) => join ' ', @parts );
}

1;
