use strict;
use warnings;

sophia_module_add('google.main', '1.0', \&init_google_main, \&deinit_google_main);

sub init_google_main {
    return 1;
}

sub deinit_google_main {
    delete_sub 'init_google_main';
    delete_sub 'deinit_google_main';
}

1;
