use strict;
use warnings;

sophia_module_add('sophia.notice', '1.0', \&init_sophia_notice, \&deinit_sophia_notice);

sub init_sophia_notice {
    sophia_command_add('sophia.notice', \&sophia_notice, 'Sends a notice.', '');
    sophia_event_privmsg_hook('sophia.notice', \&sophia_notice, 'Sends a notice.', '', SOPHIA_ACL_ADMIN);

    1;
}

sub deinit_sophia_notice {
    delete_sub 'init_sophia_notice';
    delete_sub 'sophia_notice';
    sophia_command_del 'sophia.notice';
    sophia_event_privmsg_dehook 'sophia.notice';
    delete_sub 'deinit_sophia_notice';
}

sub sophia_notice {
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
        $content =~ s/\A\s+//;
        $idx = index $content, ' ';
        return unless $idx > -1;
        $target = substr $content, 0, $idx;
        $content = substr $content, $idx + 1;
    }

    my $sophia = $args->[HEAP]->{sophia};
    $sophia->yield(notice => $target => $content);
}

1;
