use strict;
use warnings;

sophia_module_add('config.reload', '1.0', \&init_config_reload, \&deinit_config_reload);

sub init_config_reload {
    sophia_command_add('config.reload', \&config_reload, 'Reloads sophia.conf.', '');
    sophia_event_privmsg_hook('config.reload', \&config_reload, 'Reloads sophia.conf.', '');

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
    my @args = @{$args};
    my ($who, $where) = @args[ARG0, ARG1];
    $target = $target || $where->[0];

    my $perms = sophia_get_host_perms($who);
    return unless $perms & SOPHIA_ACL_FOUNDER;

    my $sophia = ${$args[HEAP]->{sophia}};

    my $message = &sophia_reload_config ? 'Config reloaded.' : 'Config failed to reload.';

    $sophia->yield(privmsg => $target => $message);
}

1;
