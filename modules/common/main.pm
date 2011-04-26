use strict;
use warnings;
require libmod::HTTPRequest;
use HTML::Entities;

sophia_module_add('common.main', '1.0', \&init_common_main, \&deinit_common_main);

sub init_common_main {
    return 1;
}

sub deinit_common_main {
    delete_sub 'init_common_main';
    delete_sub 'deinit_common_main';
}

1;
