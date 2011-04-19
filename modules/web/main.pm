use strict;
use warnings;

sophia_module_add('web.main', '1.0', \&init_web_main, \&deinit_web_main);

sub init_web_main {
    return 1;
}

sub deinit_web_main {
    delete_sub 'init_web_main';
    delete_sub 'deinit_web_main';
}

1;
