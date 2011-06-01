use strict;
use warnings;

sophia_module_add('sophia.msg', '1.0', \&init_sophia_msg, \&deinit_sophia_msg);

sub init_sophia_msg {
    sophia_global_command_add('say', \&sophia_msg, 'Sends a privmsg.', '');
    sophia_event_privmsg_hook('sophia.msg', \&sophia_msg, 'Sends a privmsg.', '', SOPHIA_ACL_ADMIN);

    1;
}

sub deinit_sophia_msg {
    delete_sub 'init_sophia_msg';
    delete_sub 'sophia_msg';
    sophia_global_command_del 'say';
    sophia_event_privmsg_dehook 'sophia.msg';
    delete_sub 'deinit_sophia_msg';
}

sub sophia_msg {
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
    $sophia->yield(privmsg => $target => $content);
}

1;
