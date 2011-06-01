use strict;
use warnings;

sophia_module_add('config.reload', '1.0', \&init_config_reload, \&deinit_config_reload);

sub init_config_reload {
    sophia_command_add('config.reload', \&config_reload, 'Reloads sophia.conf.', '', SOPHIA_ACL_FOUNDER);
    sophia_event_privmsg_hook('config.reload', \&config_reload, 'Reloads sophia.conf.', '', SOPHIA_ACL_FOUNDER);

    return 1;
}

sub deinit_config_reload {
    delete_sub 'init_config_reload';
    delete_sub 'config_reload';
    sophia_command_del 'config.reload';
    sophia_event_privmsg_dehook 'config.reload';
    delete_sub 'deinit_config_reload';
}

sub config_reload {
    my ($args, $target) = @_;
    my $where = $args->[ARG1];
    $target //= $where->[0];

    my $sophia = ${$args->[HEAP]->{sophia}};
    my $message = &sophia_reload_config ? 'Config reloaded.' : 'Config failed to reload.';

    $sophia->yield(privmsg => $target => $message);
}

1;
