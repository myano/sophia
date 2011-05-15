use strict;
use warnings;

sophia_module_add('config.main', '1.0', \&init_config_main, \&deinit_config_main);

sub init_config_main {
    return 1;
}

sub deinit_config_main {
    delete_sub 'init_config_main';
    delete_sub 'deinit_config_main';
}

1;
