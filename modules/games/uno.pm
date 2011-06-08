use strict;
use warnings;
use feature 'switch';
use List::Util qw(shuffle);

my ($UNO_STARTED, $UNO_ISDEALT, $UNO_STARTTIME, $UNO_LASTACTIVITY, $ORDER, $POINTS_POT) = (0, 0, 0, 0, 0, 0);
my ($UNO_CHAN, $DEALER, $CURRENT_TURN, @DECK, %PLAYERS_CARDS, @PLAYERS, %PLAYERS_RECORDS);
my %CARD_COLORS = (
    R   =>  '04',
    Y   =>  '08',
    G   =>  '09',
    B   =>  '12',
);
my %CARD_POINTS = (
    D2  => 20,
    R   => 20,
    S   => 20,
    W   => 50,
    WD4 => 50,
)

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
        return;
    }

    # check if the argument is an uno command
    given (uc $opts[0]) {
        when (/^CARDS|C$/) {
            # check if the game is active
            if (!$UNO_STARTED) {
                $sophia->yield(privmsg => $where->[0] => 'No uno game started.');
                return;
            }

            # check if the player is in the game
            if (!defined $PLAYERS_CARDS{$who}) {
                $sophia->yield(privmsg => $where->[0] => 'You are not in the game.');
                return;
            }

            # have the players been dealt a hand?
            if (!$UNO_ISDEALT) {
                $sophia->yield(privmsg => $where->[0] => 'The game has not started. Awaiting "UNO DEAL" command.');
                return;
            }

            # display the user's cards
            my @cards = @{$PLAYERS_CARDS{$who}};
            my $cardstr = join '  ', map { sprintf('%1$s[%2$s]%1$s', "\3$CARD_COLORS{$_}", $_) if /^([^:]+):(.+)$/; } @cards;
            
            $sophia->yield(notice => substr($who, 0, index($who, '!')) => $cardstr);
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

            # the game cannot start unless there are at least 2 players
            if (scalar(@PLAYERS) < 2) {
                $sophia->yield(privmsg => $where->[0] => 'Not enough players. A minimum of 2 players required to play uno.');
                return;
            }

            # get a deck
            my $deck = &games_uno_newdeck;
            @DECK = @{$deck};

            # give each player 7 cards
            map { push @{$PLAYERS_CARDS{$_}}, pop @DECK for (1 .. 7); } @PLAYERS;

            # set isdealt to 1
            $UNO_ISDEALT = 1;

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

            # add the dealer to the list of players
            push @PLAYERS, $who;

            $sophia->yield(privmsg => $where->[0] => 'Uno game started!');
        }
        when ('STOP') {
            if (!$UNO_STARTED) {
                $sophia->yield(privmsg => $where->[0] => 'There is no uno game started.');
                return;
            }

            my $time = time;
            my $perms = sophia_get_host_perms($who);
            $perms = $perms & (SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP | SOPHIA_ACL_FRIEND | SOPHIA_ACL_ADMIN | SOPHIA_ACL_FOUNDER);

            # can the game be stopped? Ops or higher can always stop the game
            if ($perms || $DEALER eq $who || $time - $UNO_LASTACTIVITY > $UNO_INACTIVITY_TIMEOUT) {
                &games_uno_stop;

                $sophia->yield(privmsg => $where->[0] => 'Game stopped.');
                return;
            }

            $sophia->yield(privmsg => $where->[0] => sprintf('Please wait %d seconds to stop the game.'), $UNO_INACTIVITY_TIMEOUT - ($time - $UNO_LASTACTIVITY));
        }
        when (/^TOPCARD|TOP$/) {
            # check if the game is active
            if (!$UNO_STARTED) {
                $sophia->yield(privmsg => $where->[0] => 'No uno game started.');
                return;
            }
        }
        when (/^TOP10|TOPTEN$/) {
            # if there are no records, there is no top 10
            if (! keys %PLAYERS_RECORDS ) {
                $sophia->yield(privmsg => $where->[0] => 'There are no stats at this moment.');
                return;
            }

            # get the top 10
            my $num = $scrob = 1;
            my $max = scalar(keys %PLAYERS_RECORDS);
            
            # if $max is more than 10, set $max to 10
            $max = 10 if $max > 10;

            my $points, $wins, $losses;
            my @top10 =
                # get the output string for each record
                map {
                    $points = $PLAYERS_RECORDS{$_}{POINTS};
                    $wins = $PLAYERS_RECORDS{$_}{WINS};
                    $losses = $PLAYERS_RECORDS{$_}{LOSSES};
                    sprintf("%d. \2%s\2 (\2%d\2 points in %d games, \2%d\2 win%s, %s points per game, \2%s\2 win percentage", $num++, $_, $points, $wins + $losses, $wins, $points / ($wins + $losses), $wins / ($wins + $losses));
                }
                # only get the top 10
                grep { $scrob++ <= $max; }
                # sort by highest points to lowest points
                sort { $PLAYERS_RECORDS{$a}{POINTS} > $PLAYERS_RECORDS{$b}{POINTS} }
                keys %PLAYERS_RECORDS;

            my $target = substr $who, 0, index($who, '!');
            $sophia->yield(privmsg => $target => $_) for @top10;
        }
        when (/^QUIT|Q$/) {
            # check if the game is active
            if (!$UNO_STARTED) {
                $sophia->yield(privmsg => $where->[0] => 'No uno game started.');
                return;
            }

            my $num_players = scalar @PLAYERS;

            # if there is only one player, and that player quits, stop the game
            # this case can only occur if $UNO_ISDEALT is 0. A game cannot start with just 1 player.
            if ($num_players == 1) {
                &games_uno_stop;
                $sophia->yield(privmsg => $where->[0] => 'No players left. Game stopped.');
                return;
            }

            # try to remove the user
            my @remains = grep { $_ ne $who } @PLAYERS;
            
            # did the user get removed?
            if ($num_players == scalar @remains) {
                $sophia->yield(privmsg => $where->[0] => 'You are not in the game.');
                return;
            }

            @PLAYERS = @remains;

            # for this player that quit, they lost the points in their hand.
            map {
                $PLAYERS_POT += (defined $CARD_POINTS{$2}) ? $CARD_POINTS{$2} : $1 if /^([^:]+):(.+)$/;
            } @{$PLAYERS_CARDS{$who}};

            # if this quitter doesn't exist in $PLAYERS_RECORDS, add it.
            &games_uno_setrecord({ PLAYER => $who, LOSSES => 1 });

            # if the game is on and there were 2 players and one of them quit, then the other wins
            if ($num_players == 2 && $UNO_ISDEALT && defined $PLAYERS_CARDS{$who}) {
                # give the winner the points. POINTS_POT is the points given up by players who QUIT
                &games_uno_setrecord({PLAYER => $PLAYERS[0], WINS => 1, POINTS => $POINTS_POT});

                $sophia->yield(privmsg => $where->[0] => sprintf("\2%s\2 has won the game with \2%d\2 points!", substr($PLAYERS[0], 0, index($PLAYERS[0], '!')), $PLAYERS_POT));
                &games_uno_stop;
            }

            # remove the player cards
            delete $PLAYERS_CARDS{$who};
            $sophia->yield(privmsg => $where->[0] => sprintf('Player %s has quit.'), $who);
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

sub games_uno_stop {
    $UNO_STARTED = $UNO_STARTTIME = $ORDER = $PLAYERS_POT = 0;
    $UNO_CHAN = $DEALER = $CURRENT_TURN = @DECK = %PLAYERS_CARDS = @PLAYERS = undef;
}

sub games_uno_setrecord {
    my $hashref = $_[0];
    return if !defined $hashref->{PLAYER};
    
    my $player = $hashref->{PLAYER};

    # if the player doesn't exist, add it
    $PLAYERS_RECORDS{$player} = {
        WINS    => 0,
        LOSSES  => 0,
        POINTS  => 0
    }
        if !exists $PLAYERS_RECORDS{$player};

    for ('WINS', 'LOSSES', 'POINTS') {
        $PLAYERS_RECORDS{$player}{$_} += $hashref->{$_}
            if $hashref->{$_};
    }
}

1;
