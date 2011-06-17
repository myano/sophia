use strict;
use warnings;

sophia_module_add('admin.kick', '2.0', \&init_admin_kick, \&deinit_admin_kick);

sub init_admin_kick {
    sophia_command_add('admin.kick', \&admin_kick, 'Kicks user if bot is a chan op.', '', SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP);
    sophia_event_privmsg_hook('admin.kick', \&admin_kick, 'Kicks user if bot is a chan op.', '', SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP);

    return 1;
}

sub deinit_admin_kick {
    delete_sub 'init_admin_kick';
    delete_sub 'admin_kick';
    sophia_command_del 'admin.kick';
    sophia_event_privmsg_dehook 'admin.kick';
    delete_sub 'deinit_admin_kick';
}

sub admin_kick {
    my ($args, $target) = @_;
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    my $target_chan = $where->[0];
    
    # there has to be at least ONE argument. The first part of the content is just !kick, so ignore it.
    my $idx = index $content, ' ';
    return if $idx == -1;
    $content = substr $content, $idx + 1;

    # strip out leading whitespacing
    $content =~ s/\A\s+//;

    $idx = index $content, ' ';
    return if $idx == -1;

    # if this is a privmsg case, then the first arg is the channel
    if ($target) {
        $target_chan = substr $content, 0, $idx;
        $idx = index $content, ' ';
        return if $idx == -1;
    }

    # get the kickee and kick message
    my $kickee = substr $content, 0, $idx;
    my $kick_msg = substr $content, $idx + 1;

    # do the kick
    my $sophia = ${$args->[HEAP]->{sophia}};
    $sophia->yield( kick => $target_chan => $kickee => $kick_msg );
}

1;
