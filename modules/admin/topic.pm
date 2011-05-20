use strict;
use warnings;

sophia_module_add('admin.topic', '1.0', \&init_admin_topic, \&deinit_admin_topic);

sub init_admin_topic {
    sophia_command_add('admin.topic', \&admin_topic, 'Displays or change the channel\'s topic.', '', SOPHIA_ACL_CHANGETOPIC);
    sophia_global_command_add('topic', \&admin_topic, 'Displays or change the channel\'s topic.', '', SOPHIA_ACL_CHANGETOPIC);

    return 1;
}

sub deinit_admin_topic {
    delete_sub 'init_admin_topic';
    delete_sub 'admin_topic';
    sophia_command_del 'admin.topic';
    sophia_global_command_del 'topic';
    delete_sub 'deinit_admin_topic';
}

sub admin_topic {
    my $args = $_[0];
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);

    my $sophia = ${$args->[HEAP]->{sophia}};
    $content = substr $content, index($content, ' ') + 1;
    $sophia->yield( topic => $where->[0] => $content );
}

1;
