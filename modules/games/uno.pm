use strict;
use warnings;
use feature 'switch';
use List::Util qw(shuffle);

my ($UNO_STARTED, $UNO_STARTTIME, $ORDER) = (0, 0, 0);
my ($UNO_CHAN, $DEALER, $CURRENT_TURN, @DECK, %PLAYERS_CARDS, @PLAYERS);

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

    my $sophia = ${$args->[HEAP]->{sophia}};

    # if there is no argument, state help on how to start a game.
    if (!$opts[0])
    {
        $sophia->yield(privmsg => $where->[0] => 'To start an uno game type: !uno start');
    }

    # check if the argument is an uno command
    given (uc $opts[0]) {
        when (/^CARDS|C$/) {
            # check if the game is active
            if (!$UNO_STARTED) {
                $sophia->yield(privmsg => $where->[0] => 'No uno game started.');
                return;
            }
        }
        when (/^CARDCOUNT|CC$/) {
            # check if the game is active
            if (!$UNO_STARTED) {
                $sophia->yield(privmsg => $where->[0] => 'No uno game started.');
                return;
            }
        }
        when ('DEAL') {
            # check if the game is active
            if (!$UNO_STARTED) {
                $sophia->yield(privmsg => $where->[0] => 'No uno game started.');
                return;
            }
            # check if there are enough players to start a game
            if (scalar(@nums) < 2)
            {
                $sophia->yield(privmsg => $where->[0] => 'Not enough players to start a game.');
                return;
            }
            # get a deck
            my $deck = &games_uno_newdeck;
            @DECK = @{$deck};

            # give each player 7 cards
            map { push @{$PLAYERS_CARDS{$_}}, pop @DECK for (1 .. 7); } @PLAYERS;

            $sophia->yield(privmsg => $where->[0] => 'All cards have been dealt.');

        }
        when (/^DRAW|D$/) {
            # check if the game is active
            if (!$UNO_STARTED) {
                $sophia->yield(privmsg => $where->[0] => 'No uno game started.');
                return;
            }

            # if the deck is empty, generate a new deck
            if (!scalar @DECK) {
                my $deck = &games_uno_newdeck;
                @DECK = @{$deck};
            }

            push(@{$PLAYERS_CARDS{$who}}, pop(@DECK));
        }
        when (/^JOIN|J$/) {
            # check if the game is active
            if (!$UNO_STARTED) {
                $sophia->yield(privmsg => $where->[0] => 'No uno game started.');
                return;
            }

            push (@PLAYERS, $who);
        }
        when ('PASS') {
            # check if the game is active
            if (!$UNO_STARTED) {
                $sophia->yield(privmsg => $where->[0] => 'No uno game started.');
                return;
            }
        }
        when (/^PLAY|P$/) {
            # check if the game is active
            if (!$UNO_STARTED) {
                $sophia->yield(privmsg => $where->[0] => 'No uno game started.');
                return;
            }
        }
        when ('SCORE') {
        }
        when (/^START|S$/) {
            if ($UNO_STARTED) {
                my $target = ($where->[0] eq $UNO_CHAN) ? '' : 'in %s ';
                $sophia->yield(privmsg => $where->[0] => sprintf('Game already started %sby %s', $target, $DEALER));
                return;
            }

            $UNO_STARTTIME = time();
            $UNO_STARTED = 1;
            $UNO_CHAN = $where->[0];
            $DEALER = $who;
            $sophia->yield(privmsg => $where->[0] => 'Uno game started!');

        }
        when ('STOP') {
            if (!$UNO_STARTED) {
                $sophia->yield(privmsg => $where->[0] => 'There is no uno game started.');
                return;
            }

            $UNO_STARTED = 0;
            $sophia->yield(privmsg => $where->[0] => 'The uno game has been stopped.');
        }
        when (/^TOPCARD|TOP$/) {
            # check if the game is active
            if (!$UNO_STARTED) {
                $sophia->yield(privmsg => $where->[0] => 'No uno game started.');
                return;
            }
        }
        when (/^TOP10|TOPTEN$/) {
        }
        when (/^QUIT|Q$/) {
            # check if the game is active
            if (!$UNO_STARTED) {
                $sophia->yield(privmsg => $where->[0] => 'No uno game started.');
                return;
            }
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

    # compound the decksize by 3!
    push @deck, @deck for (1 .. 3);

    # shuffle the deck a random number of times!
    my $rand= int(rand(10)) + 2;
    @deck = shuffle(@deck) for (1 .. $rand);

    return \@deck;
}

1;
