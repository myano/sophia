use strict;
use warnings;

sophia_module_add('admin.voice', '2.0', \&init_admin_voice, \&deinit_admin_voice);

sub init_admin_voice {
    sophia_command_add('admin.voice', \&admin_voice, 'Voices the user/hostmask.', '', SOPHIA_ACL_VOICE | SOPHIA_ACL_AUTOVOICE);
    sophia_event_privmsg_hook('admin.voice', \&admin_voice, 'Voices the user/hostmask.', '', SOPHIA_ACL_VOICE | SOPHIA_ACL_AUTOVOICE);

    return 1;
}

sub deinit_admin_voice {
    delete_sub 'init_admin_voice';
    delete_sub 'admin_voice';
    sophia_command_del 'admin.voice';
    sophia_event_privmsg_dehook 'admin.voice';
    delete_sub 'deinit_admin_voice';
}

sub admin_voice {
    my ($args, $target) = @_;
    my ($who, $where, $content) = ($args->[ARG0], $args->[ARG1], $args->[ARG2]);
    my $target_chan = $where->[0];

    my @parts = split ' ', $content;

    # the first arg in @parts will be the command: !voice, so toss it out
    shift @parts;

    # if this command is not ran in a channel and a channel is not provided as the first arg, do nothing
    return if !$parts[0] && $target;

    # if this command is not ran in a channel, store the target chan
    $target_chan = $parts[0] and shift @parts if $target;

    my $sophia = ${$args->[HEAP]->{sophia}};

    # if there are no params, voice the caller
    if (!$parts[0]) {
        $sophia->yield( mode => $target_chan => '+v' => substr $who, 0, index($who, '!') );
        return;
    }

    # voice the list of users
    $sophia->yield( mode => $target_chan => sprintf('+%s', 'v' x ($#parts + 1)) => join ' ', @parts );
}

1;
