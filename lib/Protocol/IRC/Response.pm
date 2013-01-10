use MooseX::Declare;
use Method::Signatures::Modifiers;

class Protocol::IRC::Response
{
    use API::Log qw(:ALL);
    use Constants;
    use POE qw(Component::IRC);
    use Protocol::IRC::Event::Public;

    method _001 (@args)
    {
        my $heap = $args[HEAP - 1];
        my $sophia = $heap->{sophia};

        if ($sophia->{password})
        {
            $sophia->yield(privmsg => 'NickServ' => sprintf('identify %s %s', $sophia->{nick}, $sophia->{password}));
        }

        if ($sophia->{usermode})
        {
            $sophia->yield(mode => sprintf('%s %s', $sophia->{nick}, $sophia->{usermode}));
        }

        for my $chan (keys %{$sophia->{channels}})
        {
            $sophia->yield(join => $chan);
        }

        $sophia->modulehandler->autoload_modules;
    }

    method _332 (@args)
    {
        my $heap = $args[HEAP - 1];
        my $sophia = $heap->{sophia};

        my $channel_data = $args[ARG2 - 1];
        my $channel = lc $channel_data->[0];
        my $topic   = $channel_data->[1];

        $sophia->{channel_topics}{$channel} = $topic;
        return;
    }

    method _default (@args)
    {
        my ($event, $args) = @args[ARG0 - 1 .. $#args];
        my @output = ( "$event: " );

        ARG: for my $arg (@$args)
        {
            if (ref $arg eq 'ARRAY')
            {
                push @output, '[' . join(',', @$arg) . ']';
                next ARG;
            }

            push @output, "'$arg'";
        }

        print join ' ', @output, "\n";
        return;
    }

    method _disconnected (@args)
    {
        my $heap = $args[HEAP - 1];
        my $sophia = $heap->{sophia};
        $sophia->yield('shutdown');
        return;
    }

    method _error (@args)
    {
        _log('sophia', $args[ARG0 - 1]);
        return;
    }

    method _public (@args)
    {
        my $heap = $args[HEAP - 1];
        my $sophia = $heap->{sophia};

        my $event = Protocol::IRC::Event::Public->new(
            sophia          => $sophia,
            sender          => $args[ARG0 - 1],
            recipients      => $args[ARG1 - 1],
            message         => $args[ARG2 - 1],
        );

        # if user is authenticated to NickServ
        if (exists $args[ARG3 - 1])
        {
            $event->hasNickServAuth(TRUE);
            $event->isNickServAuth(TRUE);
        }

        $sophia->process_input($event);
    }

    # NOTE: Do not restart like this because it's really
    # instance based.
    method _shutdown (@args)
    {
        my $heap = $args[HEAP - 1];

        if ($heap->{SYSTEM}{RESTART})
        {
            do "$sophia::BASE{BIN}/sophia";
        }

        exit;
    }

    method _sigint (@args)
    {
        my $heap = $args[HEAP - 1];
        my $sophia = $heap->{sophia};
        $sophia->yield(quit => 'Shutting down ... ');

        $args[KERNEL - 1]->sig_handled();
        return;
    }

    method _socketerr (@args)
    {
        error_log('sophia', 'Failed to connect: ' . $args[ARG0 - 1]);
        exit;
    }

    method _start (@args)
    {
        my $kernel = $args[KERNEL - 1];
        $kernel->sig(INT => 'sig_int');

        my $heap = $args[HEAP - 1];
        my $sophia = $heap->{sophia};
        if (!$sophia)
        {
            error_log('sophia', "Unable to get sophia instance from heap (start): $!\n");
        }

        $sophia->yield(register => 'all');
        $sophia->yield(connect  => { });

        return;
    }

    method _stop (@args)
    {
    }

    method _topic (@args)
    {
        my ($heap, $chan, $topic) = @args[HEAP - 1, ARG1 - 1, ARG2 - 1];
        $chan = lc $chan;

        my $sophia = $heap->{sophia};
        $sophia->{channel_topics}{$chan} = $topic;
        return;
    }
}
