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

sophia_module_add('games.roulette', '1.0', \&init_games_roulette, \&deinit_games_roulette);

sub init_games_roulette {
    sophia_command_add('games.roulette', \&games_roulette, 'Roulette game.' ,'');
    sophia_global_command_add('roulette', \&games_roulette, 'Roulette game.', '');

    return 1;
}

sub deinit_games_roulette {
    delete_sub 'init_games_roulette';
    delete_sub 'games_roulette';
    sophia_command_del 'games.roulette';
    sophia_global_command_del 'roulette';
    undef %roulette_settings;
    delete_sub 'deinit_games_roulette';
}

sub games_roulette {
    my $param = $_[0];
    my @args = @{$param};
    my ($who, $where, $content) = @args[ARG0 .. ARG2];

    my $idx = index $content, ' ';
    unless ($idx == -1) {
        $content = substr $content, $idx + 1;
        $content =~ s/^\s+//;
        $content = lc $content;

        if (index($content, 'stop') == 0) {
            return unless $roulette_settings{'GAME_STARTED'};

            if (is_admin($who) || time - $roulette_settings{'LAST_ACTIVE'} >= $roulette_settings{'TIMEOUT'}) {
                &games_roulette_stop;
                sophia_write( \$where->[0], \'Game roulette stopped.' );
            }
            else {
                sophia_write( \$where->[0], \sprintf('Please wait %d seconds to stop roulette.', $roulette_settings{'TIMEOUT'} - ( time - $roulette_settings{'LAST_ACTIVE'} )) );
            }
            return;
        }
    }

    return if $who eq $roulette_settings{'LAST_PLAYER'};

    $roulette_settings{'LAST_PLAYER'} = $who;
    $roulette_settings{'LAST_ACTIVE'} = time;
    my $rand = int(rand $roulette_settings{'COMPLEXITY'});

    if (!$roulette_settings{'GAME_STARTED'}) {
        $roulette_settings{'GAME_STARTED'} = 1;
        $roulette_settings{'NUMBER'} = $rand;
        sophia_write( \$where->[0], \$roulette_settings{'TICK'} );
        return;
    }
    
    if ($rand == $roulette_settings{'NUMBER'}) {
        sophia_kick(\$where->[0], \substr($who, 0, index($who, '!')), \$roulette_settings{'KICK_REASON'});
        sophia_write( \$where->[0], \'ENDED' );
        &games_roulette_stop;
        return;
    }

    sophia_write( \$where->[0], \$roulette_settings{'TICK'} );
}

sub games_roulette_stop {
    $roulette_settings{'GAME_STARTED'} = 0;
    $roulette_settings{'LAST_PLAYER'} = '';
    $roulette_settings{'LAST_ACTIVE'} = 0;
    $roulette_settings{'NUMBER'} = 0;
}

1;
