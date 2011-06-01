use strict;
use warnings;

sophia_module_add('admin.unquiet', '1.0', \&init_admin_unquiet, \&deinit_admin_unquiet);

sub init_admin_unquiet {
    sophia_global_command_add('unquiet', \&admin_unquiet, 'Unquiets the user/hostmask.', '', SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP);
    sophia_event_privmsg_hook('sophia.unquiet', \&admin_unquiet, 'Unquiets the user/hostmask.', '', SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP);

    return 1;
}

sub deinit_admin_unquiet {
    delete_sub 'init_admin_unquiet';
    delete_sub 'admin_unquiet';
    sophia_global_command_del 'unquiet';
    sophia_event_privmsg_dehook 'sophia.unquiet';
    delete_sub 'deinit_admin_unquiet';
}

sub admin_unquiet {
    my ($args, $target) = @_;
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    my $target_chan = $where->[0];

    my @parts = split /\s+/, $content;

    # the first arg in @parts will be the command: !unquiet, so toss it out
    shift @parts;
    return if !$parts[0];

    # if privmsg, store the target channel
    $target_chan = $parts[0] and shift @parts if $target;

    return if !$parts[0];

    my $sophia = ${$args->[HEAP]->{sophia}};
    $sophia->yield( mode => $target_chan => sprintf('-%s', 'q' x ($#parts + 1)) => join ' ', @parts );
}

1;
