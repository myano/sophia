package Protocol::IRC;
use strict;
use warnings;
use API::Log qw(error_log slog);
use POE qw(Component::IRC);

our %rawcodes = (
    _default            => \&_default,
    _start              => \&_start,
    _stop               => \&_stop,
    _001             => \&_001,
    _332             => \&_332,
    _disconnected    => \&_disconnected,
    _error           => \&_error,
    _join            => \&_join,
    _kick            => \&_kick,
    _msg             => \&_msg,
    _nick            => \&_nick,
    _notice          => \&_notice,
    _part            => \&_part,
    _public          => \&_public,
    _quit            => \&_quit,
    _shutdown        => \&_shutdown,
    _topic           => \&_topic,
    _sigint             => \&_sigint,
);

sub _default {
    my ($event, $args) = @_[ARG0 .. $#_];
    my @output = ( "$event: " );

    ARG: for my $arg (@$args) {
        if (ref $arg eq 'ARRAY') {
            push @output, '[' . join(',', @$arg) . ']';
            next ARG;
        }
        push @output, "'$arg'";
    }

    print join ' ', @output, "\n";
    return;
}

sub _start {
    my $heap = $_[HEAP];
    $_[KERNEL]->sig( INT => 'sig_int' );

    my $sophia = $heap->{sophia};
    if (!$sophia) {
        error_log('sophia', "Unable to get the sophia instance from heap (start): $!\n");
    }

    $sophia->yield(register => 'all');
    $sophia->yield(connect => { });

    return;
}

sub _stop {
}

sub _001 {
    my $heap = $_[HEAP];
    my $sophia = $heap->{sophia};

    # if sophia doesn't exist, throw an error
    if (!$sophia) {
        error_log('sophia', "Unable to get a sophia instance from heap (001): $!\n");
    }

    # identify to NickServ (if need be)
    if ($sophia->{password}) {
        $sophia->yield(privmsg => 'NickServ' => sprintf('identify %s %s', $sophia->{nick}, $sophia->{password}) );
    }
}

sub _332 {
    my ($heap, $arr_ref) = @_[HEAP, ARG2];
    my $channel = lc $arr_ref->[0];
    my $topic = $arr_ref->[1];
    $heap->{TOPICS}{$channel} = $topic;

    return;
}

sub _disconnected {
    my $heap = $_[HEAP];
    my $sophia = $heap->{sophia};
    $sophia->yield('shutdown');

    return;
}

sub _error {
    slog('sophia', $_[ARG0]);
    return;
}

sub _join {
}

sub _kick {
}

sub _msg {
}

sub _nick {
}

sub _notice {
}

sub _part {
}

sub _public {
}

sub _quit {
}

sub _shutdown {
    my $heap = $_[HEAP];

    # if there is something we need to do on exit, do it now
    if (my $hash_ref = $heap->{EVENT}{ON_SHUTDOWN}) {
        for my $func (keys %{$hash_ref}) {
            &{$func};
        }
    }

    # if we are restarting
    if ($heap->{SYSTEM}{RESTART}) {
        if ($heap->{SYSTEM}{DEBUG_MODE}) {
            do "$sophia::BASE{BIN}/sophia --debug";
        }
        else {
            do "$sophia::BASE{BIN}/sophia";
        }
    }

    exit;
}

sub _topic {
    my ($heap, $chan, $topic) = @_[HEAP, ARG1, ARG2];
    $chan = lc $chan;

    $heap->{TOPICS}{$chan} = $topic;

    return;
}

sub _sigint {
    my $heap = $_[HEAP];
    my $sophia = $heap->{sophia};
    $sophia->yield(quit => 'Shutting down ... ');

    $_[KERNEL]->sig_handled();
    return;
}

1;
