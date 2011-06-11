use strict;
use warnings;

my %roulette_settings = (
    'COMPLEXITY'    => 5, # the higher the number, the harder the game
    'TICK'          => '*TICK*',
    'KICK_REASON'   => 'SNIPED! YOU LOSE!',
    'GAME_STARTED'  => 0,
    'LAST_PLAYER'   => '',
    'LAST_ACTIVE'   => 0,
    'NUMBER'        => 0,
    'TIMEOUT'       => 60, # in seconds
);

sophia_module_add('games.roulette', '2.0', \&init_games_roulette, \&deinit_games_roulette);

sub init_games_roulette {
    sophia_command_add('games.roulette', \&games_roulette, 'Roulette game.', '');
    sophia_command_add('games.roulette:stop', \&games_roulette_stop, 'Roulette game.', '');
    sophia_command_add('games.roulette:fstop', \&games_roulette_stop, 'Roulette game.', '', SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP);

    return 1;
}

sub deinit_games_roulette {
    delete_sub 'init_games_roulette';
    delete_sub 'games_roulette';
    sophia_command_del 'games.roulette';
    sophia_command_del 'games.roulette:stop';
    sophia_command_del 'games.roulette:fstop';
    undef %roulette_settings;
    delete_sub 'deinit_games_roulette';
}

sub games_roulette {
    my $args = $_[0];
    my ($who, $where, $content) = ($args->[ARG0], $args->[ARG1], $args->[ARG2]);

    my $sophia = ${$args->[HEAP]->{sophia}};

    return if $who eq $roulette_settings{LAST_PLAYER};

    $roulette_settings{LAST_PLAYER} = $who;
    $roulette_settings{LAST_ACTIVE} = time;
    my $rand = int(rand $roulette_settings{COMPLEXITY});

    if (!$roulette_settings{GAME_STARTED}) {
        $roulette_settings{GAME_STARTED} = 1;
        $roulette_settings{NUMBER} = $rand;
        $sophia->yield(privmsg => $where->[0] => $roulette_settings{TICK});
        return;
    }
    
    if ($rand == $roulette_settings{NUMBER}) {
        $sophia->yield( kick => $where->[0] => substr($who, 0, index($who, '!')) => $roulette_settings{KICK_REASON} );
        &games_roulette_end;
        return;
    }

    $sophia->yield(privmsg => $where->[0] => $roulette_settings{TICK});
}

sub games_roulette_stop {
    my $args = $_[0];
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    my $sophia = ${$args->[HEAP]->{sophia}};

    return unless $roulette_settings{GAME_STARTED};

    if (time - $roulette_settings{LAST_ACTIVE} >= $roulette_settings{TIMEOUT}) {
        &games_roulette_end;
        $sophia->yield(privmsg => $where->[0] => 'Game roulette stopped.');
    }
    else {
        $sophia->yield(privmsg => $where->[0] => sprintf('Please wait %d seconds to stop roulette.', $roulette_settings{TIMEOUT} - (time - $roulette_settings{LAST_ACTIVE})));
    }
}

sub games_roulette_fstop {
    my $args = $_[0];
    my $where = $args->[ARG1];
    my $sophia = ${$args->[HEAP]->{sophia}};
    
    return unless $roulette_settings{GAME_STARTED};
    &games_roulette_end;
    $sophia->yield(privmsg => $where->[0] => 'Game roulette stopped.');
}

sub games_roulette_end {
    $roulette_settings{'GAME_STARTED'} = 0;
    $roulette_settings{'LAST_PLAYER'} = '';
    $roulette_settings{'LAST_ACTIVE'} = 0;
    $roulette_settings{'NUMBER'} = 0;
}

1;
