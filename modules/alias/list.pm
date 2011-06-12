use strict;
use warnings;

sophia_module_add('alias.list', '1.0', \&init_alias_list, \&deinit_alias_list);

sub init_alias_list {
    sophia_command_add('alias.list', \&alias_list, 'Lists all command aliases.', '', SOPHIA_ACL_ADMIN);
    sophia_event_privmsg_hook('alias.list', \&alias_list, 'Lists all command alias.', '', SOPHIA_ACL_ADMIN);

    return 1;
}

sub deinit_alias_list {
    delete_sub 'init_alias_list';
    delete_sub 'alias_list';
    sophia_command_del 'alias.list';
    sophia_event_privmsg_dehook 'alias.list';
    delete_sub 'deinit_alias_list';
}

sub alias_list {
    my ($args, $target) = @_;
    my ($heap, $who) = ($args->[HEAP], $args->[ARG0]);
    $target //= substr $who, 0, index($who, '!');

    return if !exists $heap->{CMD_ALIASES};

    my $sophia = ${$heap->{sophia}};
    
    my $aliases = join ' ', keys %{$heap->{CMD_ALIASES}};
    my $messages = irc_split_lines($aliases);
    
    $sophia->yield(privmsg => $target => $_) for @{$messages};
}

1;
