use strict;
use warnings;

sophia_module_add('alias.reload', '1.0', \&init_alias_reload, \&deinit_alias_reload);

sub init_alias_reload {
    sophia_command_add('alias.reload', \&alias_reload, 'Reload the alias database.', '', SOPHIA_ACL_ADMIN);

    return 1;
}

sub deinit_alias_reload {
    delete_sub 'init_alias_reload';
    delete_sub 'alias_reload';
    sophia_command_del 'alias.reload';
    delete_sub 'deinit_alias_reload';
}

sub alias_reload {
    my ($args, $target) = @_;
    $target //= $args->[ARG1]->[0];
    my $sophia = $args->[HEAP]->{sophia};

    my $ret = sophia_aliases_load(\$args->[HEAP]);

    if (!$ret) {
        $sophia->yield(privmsg => $target => 'Failed to reload aliases.');
        return;
    }

    $sophia->yield(privmsg => $target => 'Aliases reloaded');
}

1;
