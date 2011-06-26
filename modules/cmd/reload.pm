use strict;
use warnings;

sophia_module_add('cmd.reload', '1.0', \&init_cmd_reload, \&deinit_cmd_reload);

sub init_cmd_reload {
    sophia_command_add('cmd.reload', \&cmd_reload, 'Enables reloading of user-commands from the DB.', '', SOPHIA_ACL_FRIEND);

    return 1;
}

sub deinit_cmd_reload {
    delete_sub 'init_cmd_reload';
    delete_sub 'cmd_reload';
    sophia_command_del 'cmd.reload';
    delete_sub 'deinit_cmd_reload';
}

sub cmd_reload {
    my ($args, $target) = @_;
    my $where = $args->[ARG1];
    $target //= $where->[0];

    my $sophia = $args->[HEAP]->{sophia};

    # reloading is easy, just reload cmd.main
    if (sophia_reload_module('cmd.main')) {
        $sophia->yield(privmsg => $target => 'User-defined commands reloaded from DB.');
        return;
    }

    $sophia->yield(privmsg => $target => 'Unable to reload from DB.');
}

1;
