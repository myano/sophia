use strict;
use warnings;

sophia_module_add('games.uno', '2.0', \&init_games_uno, \&deinit_games_uno);

sub init_games_uno {
    sophia_global_command_add('uno', \&games_uno, 'Uno game.', '');
    sophia_global_command_add('uno:stop', \&games_uno_stop, 'Uno game.', '');
    sophia_global_command_add('uno:fstop', \&games_uno_stop, 'Uno game.', '', SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP);
    sophia_global_command_add('uno:draw', \&games_uno_draw, 'Uno game.', '');
    sophia_global_command_add('uno:play', \&games_uno_play, 'Uno game.', '');

    return 1;
}

sub deinit_games_uno {
    delete_sub 'init_games_uno';
    delete_sub 'games_uno';
    sophia_command_del 'games.uno';
    sophia_global_command_del 'uno';
    undef %uno_settings;
    delete_sub 'deinit_games_uno';
}

sub games_uno {
    my $args = $_[0];
    my ($who, $where, $content) = ($args->[ARG0], $args->[ARG1], $args->[ARG2]);

    my $sophia = ${$args->[HEAP]->{sophia}};

    # ...

    $sophia->yield(privmsg => $where->[0] => $uno_settings{TICK});
}

sub games_uno_stop {
    my $args = $_[0];
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    my $sophia = ${$args->[HEAP]->{sophia}};

    # ...
}

sub games_uno_fstop {
    my $args = $_[0];
    my $where = $args->[ARG1];
    my $sophia = ${$args->[HEAP]->{sophia}};
    
    return unless $uno_settings{GAME_STARTED};
    &games_uno_end;
    $sophia->yield(privmsg => $where->[0] => 'Game uno stopped.');
}

sub games_uno_start {
    my $args = $_[0];
    my $where = $args->[ARG1];
    my $sophia = ${$args->[HEAP]->{sophia}};

    # ...
}

sub games_uno_play {
    my $args = $_[0];
    my $where = $args->[ARG1];
    my $sophia = ${$args->[HEAP]->{sophia}};

    # ...
}

1;
