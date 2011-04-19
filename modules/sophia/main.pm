use strict;
use warnings;

sophia_module_add('sophia.main', '1.0', \&init_sophia_main, \&deinit_sophia_main);

sub init_sophia_main {
    return 1;
}

sub deinit_sophia_main {
    delete_sub 'init_sophia_main';
    delete_sub 'deinit_sophia_main';
}

1;
