use strict;
use warnings;

sophia_module_add('cmd.cmd', '1.0', \&init_cmd_cmd, \&deinit_cmd_cmd);

sub init_cmd_cmd {
    sophia_command_add('cmd.cmd', \&cmd_cmd, 'Calls a user-defined command.', '');

    return 1;
}

sub deinit_cmd_cmd {
    delete_sub 'init_cmd_cmd';
    delete_sub 'cmd_cmd';
    sophia_command_del 'cmd.cmd';
    delete_sub 'deinit_cmd_cmd';
}

sub cmd_cmd {
    my ($args, $target) = @_;
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    $target //= $where->[0];

    my $idx = index $content, ' ';
    return if $idx == -1;
    $content = substr $content, $idx + 1;

    $content =~ s/\A\s+//;
    $idx = index $content, ' ';
    $content = substr $content, 0, $idx if $idx > -1;

    $content = lc $content;

    my $cache_commands = sophia_cache_load('mod:cmd', 'commands');
    return unless $cache_commands && $cache_commands->{$content};

    my $sophia = ${$args->[HEAP]->{sophia}};
    $sophia->yield(privmsg => $target => $cache_commands->{$content});
}

1;
