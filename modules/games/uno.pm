use strict;
use warnings;
use feature 'switch';
use List::Util qw(shuffle);

my ($UNO_STARTED, $UNO_STARTTIME, $DEALER, $ORDER, $CURRENT_TURN, @DECK, %PLAYERS_CARDS, @PLAYERS);

sophia_module_add('games.uno', '1.0', \&init_games_uno, \&deinit_games_uno);

sub init_games_uno {
    sophia_global_command_add('uno', \&games_uno, 'Uno game.', '');

    return 1;
}

sub deinit_games_uno {
    delete_sub 'init_games_uno';
    delete_sub 'games_uno';
    delete_sub 'games_uno_newdeck';
    sophia_global_command_del 'uno';
    delete_sub 'deinit_games_uno';
}

sub games_uno {
    my $args = $_[0];
    my ($who, $where, $content) = ($args->[ARG0], $args->[ARG1], $args->[ARG2]);

    # the first param will be !uno, so strip it
    my @opts = split /\s+/, $content;
    shift @opts;

    # if there is no argument, do nothing
    return if !$opts[0];

    my $sophia = ${$args->[HEAP]->{sophia}};

    # check if the argument is an uno command
    given (uc $opts[0]) {
        when (/^CARDS|C$/) {
        }
        when (/^CARDCOUNT|CC$/) {
        }
        when ('DEAL') {
            foreach $player_playing (@PLAYERS)
            {
                my $val = 0;
                while ($val <= 7)
                {
                    $card = pop(@deck);
                    push(@{$PLAYERS_CARDS{$player_playing}}, $card);
                    $val = $val + 1;
                }
            }
        }
        when (/^DRAW|D$/) {
        }
        when (/^JOIN|J$/) {
            push (@PLAYERS, $who);
        }
        when ('PASS') {
        }
        when (/^PLAY|P$/) {
        }
        when ('SCORE') {
        }
        when (/^START|S$/) {
            $UNO_STARTTIME = time();
            $UNO_STARTED = 1;
            $DEALER = $who;
        }
        when ('STOP') {
            $UNO_STARTED = 0;
        }
        when (/^TOPCARD|TOP$/) {
        }
        when (/^TOP10|TOPTEN$/) {
        }
        when (/^QUIT|Q$/) {
        }

        # not a valid command, do nothing
        default { return; }
    }
}

sub games_uno_newdeck {
    my @deck = qw/R:0 R:1 R:2 R:3 R:4 R:5 R:6 R:7 R:8 R:9 R:1 R:2 R:3 R:4 R:5 R:6 R:7 R:8 R:9
                  B:0 B:1 B:2 B:3 B:4 B:5 B:6 B:7 B:8 B:9 B:1 B:2 B:3 B:4 B:5 B:6 B:7 B:8 B:9
                  Y:0 Y:1 Y:2 Y:3 Y:4 Y:5 Y:6 Y:7 Y:8 Y:9 Y:1 Y:2 Y:3 Y:4 Y:5 Y:6 Y:7 Y:8 Y:9
                  G:0 G:1 G:2 G:3 G:4 G:5 G:6 G:7 G:8 G:9 G:1 G:2 G:3 G:4 G:5 G:6 G:7 G:8 G:9
                  R:S R:S B:S B:S Y:S Y:S G:S G:S R:R R:R B:R B:R Y:R Y:R G:R G:R
                  R:D2 R:D2 B:D2 B:D2 Y:D2 Y:D2 G:D2 G:D2 W:* W:* W:* W:* WD4:* WD4* WD4:* WD4:*/;

    # shuffle the deck trice
    @deck = shuffle(@deck) for (1 .. 3);

    return \@deck;
}

1;
