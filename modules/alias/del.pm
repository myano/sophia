use strict;
use warnings;

sophia_module_add('alias.del', '1.0', \&init_alias_del, \&deinit_alias_del);

sub init_alias_del {
    sophia_command_add('alias.del', \&alias_del, 'Deletes a command alias.', '', SOPHIA_ACL_ADMIN);
    sophia_event_privmsg_hook('alias.del', \&alias_del, 'Deletes a command alias.', '', SOPHIA_ACL_ADMIN);

    return 1;
}

sub deinit_alias_del {
    delete_sub 'init_alias_del';
    delete_sub 'alias_del';
    sophia_command_del 'alias.del';
    sophia_event_privmsg_dehook 'alias.del';
    delete_sub 'deinit_alias_del';
}

sub alias_del {
    my ($args, $target) = @_;
    my ($heap, $where, $content) = ($args->[HEAP], $args->[ARG1], $args->[ARG2]);
    $target //= $where->[0];

    my @opts = split ' ', $content;
    return if scalar @opts < 2;

    return if !exists $heap->{CMD_ALIASES};

    my $sophia = ${$heap->{sophia}};
    
    if (!exists $heap->{CMD_ALIASES}{lc $opts[1]}) {
        $sophia->yield(privmsg => $target => sprintf('Alias %s does not exist.', $opts[1]));
        return;
    }

    delete $heap->{CMD_ALIASES}{lc $opts[1]};

    $sophia->yield(privmsg => $target => sprintf('Alias %s deleted.', $opts[1]));
}

1;
