use strict;
use warnings;

sophia_module_add('usercmd.del', '1.0', \&init_usercmd_del, \&deinit_usercmd_del);

sub init_usercmd_del {
    sophia_command_add('cmd.del', \&usercmd_del, 'Deletes a user-defined command.', '', SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP);
    
    return 1;
}

sub deinit_usercmd_del {
    delete_sub 'init_usercmd_del';
    delete_sub 'usercmd_del';
    sophia_command_del 'cmd.del';
    delete_sub 'deinit_usercmd_del';
}

sub usercmd_del {
    my $args = $_[0];
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    
    my $idx = index $content, ' ';
    return unless $idx > -1;

    $content = substr $content, $idx + 1;
    $content =~ s/^\s+//;

    $idx = index $content, ' ';
    $content = substr $content, 0, $idx if $idx > -1;
    
    sophia_cache_del('usercmd', $content);

    my $sophia = ${$args->[HEAP]->{sophia}};
    $sophia->yield(privmsg => $where->[0] => sprintf('%1$s%2$s%1$s deleted.', "\x02", $content));
}

1;
