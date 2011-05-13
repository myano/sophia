use strict;
use warnings;

sophia_module_add('acl.main', '1.0', \&init_acl_main, \&deinit_acl_main);

sub init_acl_main {
    return 1;
}

sub deinit_acl_main {
    delete_sub 'init_acl_main';
    delete_sub 'deinit_acl_main';
}

1;
