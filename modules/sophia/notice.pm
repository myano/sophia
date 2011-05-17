use strict;
use warnings;

sophia_module_add('sophia.notice', '1.0', \&init_sophia_notice, \&deinit_sophia_notice);

sub init_sophia_notice {
    sophia_global_command_add('notice', \&sophia_notice, 'Sends a notice.', '');
    sophia_event_privmsg_hook('sophia.notice', \&sophia_notice, 'Sends a notice.', '');

    1;
}

sub deinit_sophia_notice {
    delete_sub 'init_sophia_notice';
    delete_sub 'sophia_notice';
    sophia_global_command_del 'notice';
    sophia_event_privmsg_dehook 'sophia.notice';
    delete_sub 'deinit_sophia_notice';
}

sub sophia_notice {
    my $args = $_[0];
    my @args = @{$args};
    my ($who, $where, $content) = @args[ARG0 .. ARG2];
    my $target = $where->[0];
    my $self = &sophia_get_config;
    my $isSelf = lc $target eq lc $self->{nick};

    my $perms = sophia_get_host_perms($who);
    return unless $perms & (SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP);

    my $idx = index $content, ' ';
    return unless $idx > -1;

    $content = substr $content, $idx + 1;

    # if the target is sophia, get first arg as the target
    if ($isSelf) {
        $content =~ s/^\s+//;
        $idx = index $content, ' ';
        return unless $idx > -1 || $perms & SOPHIA_ACL_ADMIN;
        $target = substr $content, 0, $idx;
        $content = substr $content, $idx + 1;
    }

    my $sophia = ${$args[HEAP]->{sophia}};
    $sophia->yield(notice => $target => $content);
}

1;
