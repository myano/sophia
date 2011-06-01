use strict;
use warnings;

sophia_module_add('sophia.action', '1.0', \&init_sophia_action, \&deinit_sophia_action);

sub init_sophia_action {
    sophia_global_command_add('action', \&sophia_action, 'Sends an action.', '');
    sophia_event_privmsg_hook('sophia.action', \&sophia_action, 'Sends an action.', '', SOPHIA_ACL_ADMIN);

    1;
}

sub deinit_sophia_action {
    delete_sub 'init_sophia_action';
    delete_sub 'sophia_action';
    sophia_global_command_del 'action';
    sophia_event_privmsg_dehook 'sophia.action';
    delete_sub 'deinit_sophia_action';
}

sub sophia_action {
    my ($args, $target) = @_;
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    $target //= $where->[0];

    my $self = &sophia_get_config;
    my $isSelf = lc $target eq lc $self->{nick};

    my $idx = index $content, ' ';
    return unless $idx > -1;

    $content = substr $content, $idx + 1;

    # if the target is sophia, get first arg as the target
    if ($isSelf) {
        $content =~ s/^\s+//;
        $idx = index $content, ' ';
        return unless $idx > -1;
        $target = substr $content, 0, $idx;
        $content = substr $content, $idx + 1;
    }

    my $sophia = ${$args->[HEAP]->{sophia}};
    $sophia->yield(ctcp => $target => sprintf('ACTION %s', $content));
}

1;
