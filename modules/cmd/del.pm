use strict;
use warnings;

sophia_module_add('cmd.del', '1.0', \&init_cmd_del, \&deinit_cmd_del);

sub init_cmd_del {
    sophia_command_add('cmd.del', \&cmd_del, 'Deletes a user-defined command.', '', SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP);
    
    return 1;
}

sub deinit_cmd_del {
    delete_sub 'init_cmd_del';
    delete_sub 'cmd_del';
    sophia_command_del 'cmd.del';
    delete_sub 'deinit_cmd_del';
}

sub cmd_del {
    my $args = $_[0];
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    
    my $idx = index $content, ' ';
    return unless $idx > -1;

    $content = substr $content, $idx + 1;
    $content =~ s/^\s+//;

    $idx = index $content, ' ';
    $content = substr $content, 0, $idx if $idx > -1;
    
    my $cache_commands = sophia_cache_load('mod:cmd', 'commands');
    return unless $cache_commands && $cache_commands->{$content};

    delete $cache_commands->{$content};

    my $sophia = ${$args->[HEAP]->{sophia}};
    $sophia->yield(privmsg => $where->[0] => sprintf('%1$s%2$s%1$s deleted.', "\x02", $content));
}

1;
