use strict;
use warnings;

sophia_module_add('alias.main', '1.0', \&init_alias_main, \&deinit_alias_main);

sub init_alias_main {
    # load the aliases
    sophia_set('LOAD_ALIASES', 1);

    return 1;
}

sub deinit_alias_main {
    delete_sub 'init_alias_main';
    delete_sub 'deinit_alias_main';
}

1;
