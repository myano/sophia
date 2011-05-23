use strict;
use warnings;

sophia_module_add('usercmd.cmd', '1.0', \&init_usercmd_cmd, \&deinit_usercmd_cmd);

sub init_usercmd_cmd {
    sophia_global_command_add('cmd', \&usercmd_cmd, 'Calls a user-defined command.', '');

    return 1;
}

sub deinit_usercmd_cmd {
    delete_sub 'init_usercmd_cmd';
    delete_sub 'usercmd_cmd';
    sophia_global_command_del 'cmd';
    delete_sub 'deinit_usercmd_cmd';
}

sub usercmd_cmd {
    my $args = $_[0];
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);

    my $idx = index $content, ' ';
    return unless $idx > -1;
    $content = substr $content, $idx + 1;

    $content =~ s/^\s+//;
    $idx = index $content, ' ';
    $content = substr $content, 0, $idx if $idx > -1;

    $content = lc $content;

    $content = sophia_cache_load('usercmd', $content);

    my $sophia = ${$args->[HEAP]->{sophia}};
    $sophia->yield(privmsg => $where->[0] => $content);
}

1;
