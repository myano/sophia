use strict;
use warnings;

sophia_module_add('cmd.list', '1.0', \&init_cmd_list, \&deinit_cmd_list);

sub init_cmd_list {
    sophia_command_add('cmd.list', \&cmd_list, 'Lists all user-defined commands.', '');

    return 1;
}

sub deinit_cmd_list {
    delete_sub 'init_cmd_list';
    delete_sub 'cmd_list';
    sophia_command_del 'cmd.list';
    delete_sub 'deinit_cmd_list';
}

sub cmd_list {
    my ($args, $target) = @_;
    my $where = $args->[ARG1];
    $target //= $where->[0];

    my $sophia = $args->[HEAP]->{sophia};

    # get all user-defined commands
    my $cache_commands = sophia_cache_load('mod:cmd', 'commands');
    return unless $cache_commands;

    my $commands = join ' ', keys %{$cache_commands};
    my $messages = irc_split_lines($commands);
    $sophia->yield(privmsg => $target => $_) for @{$messages};
}

1;
