use strict;
use warnings;

sophia_module_add('common.ping', '1.0', \&init_common_ping, \&deinit_common_ping);

sub init_common_ping {
    sophia_command_add('common.ping', \&common_ping, 'Pings sophia and she will respond with a pong.', '');
    sophia_event_privmsg_hook('common.ping', \&common_ping, 'Pings sophia and she will respond with a pong.', '');

    return 1;
}

sub deinit_common_ping {
    delete_sub 'init_common_ping';
    delete_sub 'common_ping';
    sophia_command_del 'common.ping';
    sophia_event_privmsg_dehook 'common.ping';
    delete_sub 'deinit_common_ping';
}

sub common_ping {
    my ($args, $target) = @_;
    $target //= $args->[ARG1]->[0];

    my $sophia = $args->[HEAP]->{sophia};
    $sophia->yield(privmsg => $target => 'pong');
}

1;
