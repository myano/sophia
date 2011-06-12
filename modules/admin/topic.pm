use strict;
use warnings;

sophia_module_add('admin.topic', '2.0', \&init_admin_topic, \&deinit_admin_topic);

sub init_admin_topic {
    sophia_command_add('admin.topic', \&admin_topic, 'Displays or change the channel\'s topic.', '', SOPHIA_ACL_CHANGETOPIC);
    sophia_event_privmsg_hook('admin.topic', \&admin_topic, 'Displays or change the channel\'s topic.', '', SOPHIA_ACL_CHANGETOPIC);

    return 1;
}

sub deinit_admin_topic {
    delete_sub 'init_admin_topic';
    delete_sub 'admin_topic';
    sophia_command_del 'admin.topic';
    sophia_event_privmsg_dehook 'admin.topic';
    delete_sub 'deinit_admin_topic';
}

sub admin_topic {
    my ($args, $target) = @_;
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    my $target_chan = $where->[0];

    # there needs to be at least ONE argument. Since the initial word is the command: !topic, ignore it
    my $idx = index $content, ' ';
    return if $idx == -1;
    $content = substr $content, $idx + 1;

    # if this is a privmsg case, then the first arg is the channel
    if ($target) {
        # if there is no channel, do nothing
        $idx = index $content, ' ';
        return if $idx == -1;

        # store the target channel
        $target_chan = substr $content, 0, $idx;

        # set the topic message to be everything after $idx
        $content = substr $content, $idx + 1;
    }

    return if !$content;

    my $sophia = ${$args->[HEAP]->{sophia}};
    $sophia->yield( topic => $target_chan => $content );
}

1;
