use strict;
use warnings;

sophia_module_add('cmd.set', '1.0', \&init_cmd_set, \&deinit_cmd_set);

sub init_cmd_set {
    sophia_command_add('cmd.set', \&cmd_set, 'Sets a user-defined command.', '', SOPHIA_ACL_VOICE | SOPHIA_ACL_AUTOVOICE);
    
    return 1;
}

sub deinit_cmd_set {
    delete_sub 'init_cmd_set';
    delete_sub 'cmd_set';
    sophia_command_del 'cmd.set';
    delete_sub 'deinit_cmd_set';
}

sub cmd_set {
    my $args = $_[0];
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    
    my $idx = index $content, ' ';
    return if $idx == -1;

    $content = substr $content, $idx + 1;
    $content =~ s/^\s+//;
    $idx = index $content, ' ';
    return if $idx == -1;

    my $command = substr $content, 0, $idx;

    $command = lc $command;
    $content = substr $content, $idx + 1;
    
    # get the commands
    my $cache_commands = sophia_cache_load('mod:cmd', 'commands');
    return if !$cache_commands;

    # set it
    $cache_commands->{$command} = $content;

    my $sophia = ${$args->[HEAP]->{sophia}};
    $sophia->yield(privmsg => $where->[0] => sprintf('%1$s%2$s%1$s set.', "\x02", $command));
}

1;
