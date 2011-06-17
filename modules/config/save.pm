use strict;
use warnings;

sophia_module_add('config.save', '1.0', \&init_config_save, \&deinit_config_save);

sub init_config_save {
    sophia_command_add('config.save', \&config_save, 'Save sophia.conf file.', '', SOPHIA_ACL_MASTER);
    sophia_event_privmsg_hook('config.save', \&config_save, 'Save sophia.conf file.', '', SOPHIA_ACL_MASTER);

    return 1;
}

sub deinit_config_save {
    delete_sub 'init_config_save';
    delete_sub 'config_save';
    sophia_command_del 'config.save';
    sophia_event_privmsg_dehook 'config.save';
    delete_sub 'deinit_config_save';
}

sub config_save {
    my ($args, $target) = @_;
    my $where = $args->[ARG1];
    $target //= $where->[0];

    my $sophia = ${$args->[HEAP]->{sophia}};
    my $message = &sophia_save_config ? 'Config saved.' : 'Config failed to save.';

    $sophia->yield(privmsg => $target => $message);
}

1;
