use strict;
use warnings;

sophia_module_add('usercmd.set', '1.0', \&init_usercmd_set, \&deinit_usercmd_set);

sub init_usercmd_set {
    sophia_command_add('cmd.set', \&usercmd_set, 'Sets a user-defined command.', '', SOPHIA_ACL_VOICE | SOPHIA_ACL_AUTOVOICE);
    
    return 1;
}

sub deinit_usercmd_set {
    delete_sub 'init_usercmd_set';
    delete_sub 'usercmd_set';
    sophia_command_del 'cmd.set';
    delete_sub 'deinit_usercmd_set';
}

sub usercmd_set {
    my $args = $_[0];
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    
    my $idx = index $content, ' ';
    return unless $idx > -1;

    $content = substr $content, $idx + 1;
    $content =~ s/^\s+//;
    $idx = index $content, ' ';
    return unless $idx > -1;

    my $command = substr $content, 0, $idx;

    $command = lc $command;
    $content = substr $content, $idx + 1;
    
    my $ret = sophia_cache_store("usercmd/$command", $content);
    return unless $ret;

    my $sophia = ${$args->[HEAP]->{sophia}};
    $sophia->yield(privmsg => $where->[0] => sprintf('%1$s%2$s%1$s set.', "\x02", $command));
}

1;
