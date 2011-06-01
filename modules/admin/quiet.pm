use strict;
use warnings;

sophia_module_add('admin.quiet', '1.0', \&init_admin_quiet, \&deinit_admin_quiet);

sub init_admin_quiet {
    sophia_global_command_add('quiet', \&admin_quiet, 'Quiets the user/hostmask.', '', SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP);
    sophia_event_privmsg_hook('sophia.quiet', \&admin_quiet, 'Quiets the user/hostmask.', '', SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP);

    return 1;
}

sub deinit_admin_quiet {
    delete_sub 'init_admin_quiet';
    delete_sub 'admin_quiet';
    sophia_global_command_del 'quiet';
    sophia_event_privmsg_dehook 'sophia.quiet';
    delete_sub 'deinit_admin_quiet';
}

sub admin_quiet {
    my ($args, $target) = @_;
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    my $target_chan = $where->[0];

    my @parts = split /\s+/, $content;

    # the first arg in @parts will be the command: !quiet, so toss it out
    shift @parts;
    return if !$parts[0];

    # if privmsg, store the target channel
    $target_chan = $parts[0] and shift @parts if $target;

    return if !$parts[0];

    my $sophia = ${$args->[HEAP]->{sophia}};
    $sophia->yield( mode => $target_chan => sprintf('+%s', 'q' x ($#parts + 1)) => join ' ', @parts );
}

1;
