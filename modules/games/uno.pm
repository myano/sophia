use strict;
use warnings;
use feature 'switch';
use List::Util qw(shuffle);

my @DECK = my %PLAYERS_CARDS = my @PLAYERS = my %PLAYERS_RECORDS = ();
my %UNO_DEFAULTS = my %UNO_STATES = (
    CHANNEL                 => undef,
    CURRENTTURN             => undef,
    DEALER                  => undef,
    INACTIVITY_TIMEOUT      => 30,
    ISDEALT                 => 0,
    LASTACTIVITY            => 0,
    ORDER                   => 0,
    POINTS_POT              => 0,
    STARTED                 => 0,
    STARTTIME               => 0,
);
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
);

sophia_module_add('games.uno', '1.0', \&init_games_uno, \&deinit_games_uno);

sub init_games_uno {
    sophia_command_add('games.uno', \&games_uno, 'Uno game.', '');

    return 1;
}

sub deinit_games_uno {
    delete_sub 'init_games_uno';
    delete_sub 'games_uno';
    delete_sub 'games_uno_newdeck';
    delete_sub 'games_uno_stop';
    delete_sub 'games_uno_setrecord';
    sophia_command_del 'games.uno';
    delete_sub 'deinit_games_uno';
}

sub games_uno {
    my $args = $_[0];
    my ($who, $where, $content) = ($args->[ARG0], $args->[ARG1], $args->[ARG2]);
    my $nick = substr $who, 0, index($who, '!');

    # the first param will be !uno, so strip it
    my @opts = split ' ', $content;
    shift @opts;

    my $sophia = ${$args->[HEAP]->{sophia}};

    # if there is no argument, state help on how to start a game.
    if (!$opts[0])
    {
        $sophia->yield(privmsg => $where->[0] => 'To start an uno game use: uno start');
        return;
    }

    # check if the argument is an uno command
    given (uc $opts[0]) {
        when (/\A(CARDS|C)\z/) {
            # check if the game is active
            if (!$UNO_STATES{STARTED}) {
                $sophia->yield(privmsg => $where->[0] => 'No uno game started.');
                return;
            }

            # check if the player is in the game
            if (!defined $PLAYERS_CARDS{$who}) {
                $sophia->yield(privmsg => $where->[0] => 'You are not in the game.');
                return;
            }

            # have the players been dealt a hand?
            if (!$UNO_STATES{ISDEALT}) {
                $sophia->yield(privmsg => $where->[0] => 'The game has not started. Awaiting "UNO DEAL" command.');
                return;
            }

            # display the user's cards
            my @cards = @{$PLAYERS_CARDS{$who}};
            my $cardstr = join '  ', map { sprintf('%1$s[%2$s]%1$s', "\3$CARD_COLORS{$_}", $_) if /\A([^:]+):(.+)\z/; } @cards;
            
            $sophia->yield(notice => $nick => $cardstr);
        }
        when (/\A(CARDCOUNT|CC)\z/) {
            # check if the game is active
            if (!$UNO_STATES{STARTED}) {
                $sophia->yield(privmsg => $where->[0] => 'No uno game started.');
                return;
            }
        }
        when ('DEAL') {
            # check if the game is active
            if (!$UNO_STATES{STARTED}) {
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

            # assign player order
            push @PLAYERS, $_ for keys %PLAYERS_CARDS;

            # shuffle the order of the players 3 times
            @PLAYERS = shuffle(@PLAYERS) for (1 .. 3);

            # give each player 7 cards
            map { push @{$PLAYERS_CARDS{$_}}, shift @DECK for (1 .. 7); } keys %PLAYERS_CARDS;

            # set isdealt to 1
            $UNO_STATES{ISDEALT} = 1;

            $sophia->yield(privmsg => $where->[0] => 'All cards have been dealt.');

        }
        when (/\A(DRAW|D)\z/) {
            # check if the game is active
            if (!$UNO_STATES{STARTED}) {
                $sophia->yield(privmsg => $where->[0] => 'No uno game started.');
                return;
            }

            # if the deck is empty, generate a new deck
            if (!scalar @DECK) {
                my $deck = &games_uno_newdeck;
                @DECK = @{$deck};
            }

            push(@{$PLAYERS_CARDS{$who}}, shift(@DECK));
        }
        when (/\A(JOIN|J)\z/) {
            # check if the game is active
            if (!$UNO_STATES{STARTED}) {
                $sophia->yield(privmsg => $where->[0] => 'No uno game started.');
                return;
            }

            # if the game is dealt, the player can't join
            if ($UNO_STATES{ISDEALT}) {
                # if the player is already in the game
                if (exists $PLAYERS_CARDS{$who}) {
                    $sophia->yield(privmsg => $where->[0] => 'You are already in the game.');
                    return;
                }

                # otherwise, too bad
                $sophia->yield(privmsg => $where->[0] => 'Sorry, the game is already in session.');
                return;
            }

            # if the user is already joined, don't re-add the user.
            if (exists $PLAYERS_CARDS{$who}) {
                $sophia->yield(privmsg => $where->[0] => 'You\'re already in the game.');
                return;
            }

            $PLAYERS_CARDS{$who} = [];
        }
        when ('PASS') {
            # check if the game is active
            if (!$UNO_STATES{STARTED}) {
                $sophia->yield(privmsg => $where->[0] => 'No uno game started.');
                return;
            }
        }
        when (/\A(PLAY|P)\z/) {
            # check if the game is active
            if (!$UNO_STATES{STARTED}) {
                $sophia->yield(privmsg => $where->[0] => 'No uno game started.');
                return;
            }
        }
        when ('SCORE') {
        }
        when (/\A(START|S)\z/) {
            if ($UNO_STATES{STARTED}) {
                my $target = ($where->[0] eq $UNO_STATES{CHANNEL}) ? '' : 'in %s ';
                $sophia->yield(privmsg => $where->[0] => sprintf('Game already started %sby %s', $target, $UNO_STATES{DEALER}));
                return;
            }

            $UNO_STATES{STARTTIME} = time();
            $UNO_STATES{STARTED} = 1;
            $UNO_STATES{CHANNEL} = $where->[0];
            $UNO_STATES{DEALER} = $who;

            # add the dealer to the list of players
            $PLAYERS_CARDS{$who} = [];

            $sophia->yield(privmsg => $where->[0] => sprintf('Uno game started by %s!', $nick));
        }
        when ('STOP') {
            if (!$UNO_STATES{STARTED}) {
                $sophia->yield(privmsg => $where->[0] => 'There is no uno game started.');
                return;
            }

            my $time = time;
            my $perms = sophia_get_host_perms($who);
            $perms = $perms & (SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP | SOPHIA_ACL_FRIEND | SOPHIA_ACL_ADMIN | SOPHIA_ACL_FOUNDER);

            # can the game be stopped? Ops or higher can always stop the game
            if ($perms || $UNO_STATES{DEALER} eq $who || $time - $UNO_STATES{LASTACTIVITY} > $UNO_STATES{INACTIVITY_TIMEOUT}) {
                &games_uno_stop;

                $sophia->yield(privmsg => $where->[0] => 'Game stopped.');
                return;
            }

            $sophia->yield(privmsg => $where->[0] => sprintf('Please wait %d seconds to stop the game.'), $UNO_STATES{INACTIVITY_TIMEOUT} - ($time - $UNO_STATES{LASTACTIVITY}));
        }
        when (/\A(TOPCARD|TOP)\z/) {
            # check if the game is active
            if (!$UNO_STATES{STARTED}) {
                $sophia->yield(privmsg => $where->[0] => 'No uno game started.');
                return;
            }

            # is the game dealt?
            if (!$UNO_STATES{ISDEALT}) {
                $sophia->yield(privmsg => $where->[0] => 'The game hasn\'t started yet.');
                return;
            }

            # if the deck is empty, get a new deck
            if (!scalar @DECK) {
                my $deck_ref = games_uno_newdeck();
                @DECK = @{$deck_ref};
            }

            # get the top card
            my $topcard = $DECK[0];
            my ($color, $card) = ($topcard =~ m/\A([^:]+):(.+)\z/;);
            $sophia->yield(privmsg => $where->[0] => sprintf('Top card: %1%s%2$s[%3$s]%2$s%1$s', "\2", $CARD_COLORS{$color}, $card));
        }
        when (/\A(TOP10|TOPTEN)\z/) {
            # if there are no records, there is no top 10
            if (! keys %PLAYERS_RECORDS ) {
                $sophia->yield(privmsg => $where->[0] => 'There are no stats at this moment.');
                return;
            }

            # get the top 10
            my $num = my $scrob = 1;
            my $max = scalar(keys %PLAYERS_RECORDS);
            
            # if $max is more than 10, set $max to 10
            $max = 10 if $max > 10;

            my ($points, $wins, $losses);
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

            $sophia->yield(privmsg => $nick => $_) for @top10;
        }
        when (/\A(QUIT|Q)\z/) {
            # check if the game is active
            if (!$UNO_STATES{STARTED}) {
                $sophia->yield(privmsg => $where->[0] => 'No uno game started.');
                return;
            }

            my $num_players = scalar @PLAYERS;

            # if there is only one player, and that player quits, stop the game
            # this case can only occur if ISDEALT is 0. A game cannot start with just 1 player.
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
                $UNO_STATES{POINTS_POT} += (defined $CARD_POINTS{$2}) ? $CARD_POINTS{$2} : $1 if /\A([^:]+):(.+)\z/;
            } @{$PLAYERS_CARDS{$who}};

            # if this quitter doesn't exist in $PLAYERS_RECORDS, add it.
            &games_uno_setrecord({ PLAYER => $who, LOSSES => 1 });

            # if the game is on and there were 2 players and one of them quit, then the other wins
            if ($num_players == 2 && $UNO_STATES{ISDEALT} && defined $PLAYERS_CARDS{$who}) {
                # give the winner the points. POINTS_POT is the points given up by players who QUIT
                &games_uno_setrecord({PLAYER => $PLAYERS[0], WINS => 1, POINTS => $UNO_STATES{POINTS_POT}});

                $sophia->yield(privmsg => $where->[0] => sprintf("\2%s\2 has won the game with \2%d\2 points!", substr($PLAYERS[0], 0, index($PLAYERS[0], '!')), $UNO_STATES{POINTS_POT}));
                &games_uno_stop;
            }

            # TODO: Make sure to assign the NEXT player who should go after this player quits

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
    %UNO_STATES = %UNO_DEFAULTS;
    @DECK = @PLAYERS = %PLAYERS_CARDS = ();
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
