use strict;
use warnings;

sophia_module_add('admin.main', '1.0', \&init_admin_main, \&deinit_admin_main);

sub init_admin_main {
    return 1;
}

sub deinit_admin_main {
    delete_sub 'init_admin_main';
    delete_sub 'deinit_admin_main';
}

1;
