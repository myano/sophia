use strict;
use warnings;

sophia_module_add('games.main', '1.0', \&init_games_main, \&deinit_games_main);

sub init_games_main {
    return 1;
}

sub deinit_games_main {
    delete_sub 'init_games_main';
    delete_sub 'deinit_games_main';
}

1;
