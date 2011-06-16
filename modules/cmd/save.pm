use strict;
use warnings;

my $cmd_db = 'etc/usercmd.db';

sophia_module_add('cmd.save', '1.0', \&init_cmd_save, \&deinit_cmd_save);

sub init_cmd_save {
    sophia_command_add('cmd.save', \&cmd_save, 'Saves the user-defined commands.', '', SOPHIA_ACL_FRIEND);
    sophia_event_privmsg_hook('cmd.save', \&cmd_save, 'Saves the user-defined commands.', '', SOPHIA_ACL_FRIEND);

    return 1;
}

sub deinit_cmd_save {
    delete_sub 'init_cmd_save';
    delete_sub 'cmd_save';
    sophia_command_del 'cmd.save';
    sophia_event_privmsg_dehook 'cmd.save';
    delete_sub 'deinit_cmd_save';
}

sub cmd_save {
    my ($args, $target) = @_;
    my $where = $args->[ARG1];
    $target //= $where->[0];

    my $cmds = &sophia_cache_load('mod:cmd', 'commands');

    open my $fh, '>', $cmd_db or sophia_log('sophia', "Unable to open $cmd_db file for saving: $!") and return;
    print {$fh} $_, ' ', $cmds->{$_} for keys %{$cmds};
    close $fh;

    my $sophia = ${$args->[HEAP]->{sophia}};
    $sophia->yield(privmsg => $target => 'User-defined commands saved to DB.');
}

1;
