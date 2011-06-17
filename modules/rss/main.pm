use strict;
use warnings;

sophia_module_add('rss.main', '1.0', \&init_rss_main, \&deinit_rss_main);

sub init_rss_main {
    return 1;
}

sub deinit_rss_main {
    delete_sub 'init_rss_main';
    delete_sub 'deinit_rss_main';
}

1;
