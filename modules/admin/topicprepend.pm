use strict;
use warnings;

sophia_module_add('admin.topicprepend', '1.0', \&init_admin_topicprepend, \&deinit_admin_topicprepend);

sub init_admin_topicprepend {
    sophia_command_add('admin.topicprepend', \&admin_topicprepend, 'Appends to the topic.', '', SOPHIA_ACL_CHANGETOPIC);
    
    return 1;
}

sub deinit_admin_topicprepend {
    delete_sub 'init_admin_topicprepend';
    delete_sub 'admin_topicprepend';
    sophia_command_del 'admin.topicprepend';
    delete_sub 'deinit_admin_topicprepend';
}

sub admin_topicprepend {
    my ($args, $target) = @_;
    my ($where, $content, $heap) = ($args->[ARG1], $args->[ARG2], $args->[HEAP]);

    my $idx = index $content, ' ';
    return if $idx == -1;
    $content = substr $content, $idx + 1;

    my $target_chan = lc $where->[0];

    # if privmsg
    if ($target) {
        # first arg = chan; second arg = topic
        $idx = index $content, ' ';
        return if $idx == -1;

        $target_chan = lc substr $content, 0, $idx;
        $content = substr $content, $idx + 1;
    }

    return if !$content;

    # if no topic found, do nothing
    return if !exists $heap->{TOPICS}{$target_chan};

    my $topic = $heap->{TOPICS}{$target_chan};
    $topic = ' | ' . $topic if length $topic;
    $topic = $content . $topic;

    my $sophia = ${$heap->{sophia}};
    $sophia->yield( topic => $target_chan => $topic );
}

1;
