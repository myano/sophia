use strict;
use warnings;

sophia_module_add('config.save', '1.0', \&init_config_save, \&deinit_config_save);

sub init_config_save {
    sophia_command_add('config.save', \&config_save, 'Save sophia.conf file.', '');
    sophia_event_privmsg_hook('config.save', \&config_save, 'Save sophia.conf file.', '');

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
    my @args = @{$args};
    my ($who, $where) = @args[ARG0 .. ARG1];
    $target = $target || $where->[0];

    my $perms = sophia_get_host_perms($who);
    return unless $perms & SOPHIA_ACL_FOUNDER;

    my $sophia = ${$args[HEAP]->{sophia}};

    my $message = &sophia_save_config ? 'Config saved.' : 'Config failed to save.';

    $sophia->yield(privmsg => $target => $message);
}

1;
