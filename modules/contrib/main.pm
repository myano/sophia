use strict;
use warnings;

sophia_module_add('contrib.main', '1.0', \&init_contrib_main, \&deinit_contrib_main);

sub init_contrib_main {
    return 1;
}

sub deinit_contrib_main {
    delete_sub 'init_contrib_main';
    delete_sub 'deinit_contrib_main';
}

1;
