use strict;
use warnings;

sophia_module_add('alias.save', '1.0', \&init_alias_save, \&deinit_alias_save);

sub init_alias_save {
    sophia_command_add('alias.save', \&alias_save, 'Saves command aliases to db.', '', SOPHIA_ACL_ADMIN);
    sophia_event_privmsg_hook('alias.save', \&alias_save, 'Saves command aliases to db.', '', SOPHIA_ACL_ADMIN);

    return 1;
}

sub deinit_alias_save {
    delete_sub 'init_alias_save';
    delete_sub 'alias_save';
    sophia_command_del 'alias.save';
    sophia_event_privmsg_dehook 'alias.save';
    delete_sub 'deinit_alias_save';
}

sub alias_save {
    my ($args, $target) = @_;
    my $heap = $args->[HEAP];
    return if !exists $heap->{CMD_ALIASES};

    $target //= $args->[ARG1]->[0];

    my $alias_db = $sophia::CONFIGURATIONS{ALIAS_DB};

    open my $fh, '>', $alias_db or sophia_log('sophia', "Unable to open $alias_db for writing: $!") and return;
    print {$fh} sprintf('%s %s%s', $_, $heap->{CMD_ALIASES}{$_}, "\n") for keys %{$heap->{CMD_ALIASES}};
    close $fh;

    my $sophia = $heap->{sophia};
    $sophia->yield(privmsg => $target => 'Aliases saved to DB.');
}

1;
