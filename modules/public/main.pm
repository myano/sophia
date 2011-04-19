use strict;
use warnings;

sophia_module_add('public.main', '1.0', \&init_public_main, \&deinit_public_main);

sub init_public_main {
    return 1;
}

sub deinit_public_main {
    delete_sub 'init_public_main';
    delete_sub 'deinit_public_main';
}

1;
