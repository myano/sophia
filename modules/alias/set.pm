use strict;
use warnings;

sophia_module_add('alias.set', '1.0', \&init_alias_set, \&deinit_alias_set);

sub init_alias_set {
    sophia_command_add('alias.set', \&alias_set, 'Sets a command alias.', '', SOPHIA_ACL_ADMIN);
    sophia_event_privmsg_hook('alias.set', \&alias_set, 'Sets a command alias.', '', SOPHIA_ACL_ADMIN);

    return 1;
}

sub deinit_alias_set {
    delete_sub 'init_alias_set';
    delete_sub 'alias_set';
    sophia_command_del 'alias.set';
    sophia_event_privmsg_dehook 'alias.set';
    delete_sub 'deinit_alias_set';
}

sub alias_set {
    my ($args, $target) = @_;
    my ($heap, $where, $content) = ($args->[HEAP], $args->[ARG1], $args->[ARG2]);
    $target //= $where->[0];

    my @opts = split ' ', $content;
    return if scalar @opts < 3;

    return if !exists $heap->{CMD_ALIASES};

    my $sophia = $heap->{sophia};
    
    $heap->{CMD_ALIASES}{lc $opts[1]} = lc $opts[2];

    $sophia->yield(privmsg => $target => sprintf('alias %s = %s.', $opts[1], $opts[2]));
}

1;
