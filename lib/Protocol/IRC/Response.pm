use MooseX::Declare;
use Method::Signatures::Modifiers;

class Protocol::IRC::Response
{
    use API::Log qw(:ALL);
    use Constants;
    use MIME::Base64;
    use POE qw(Component::IRC);
    use Protocol::IRC::Event::PrivateMessage;
    use Protocol::IRC::Event::Public;

    method _001 (@args)
    {
        my $heap = $args[HEAP - 1];
        my $sophia = $heap->{sophia};
        $sophia->is_connected(TRUE);

        if (!$sophia->is_authenticated)
        {
            if ($sophia->{password})
            {
                $sophia->yield(privmsg => 'NickServ' => sprintf('identify %s %s', $sophia->{nick}, $sophia->{password}));
            }
        }

        if ($sophia->{usermode})
        {
            $sophia->yield(mode => sprintf('%s %s', $sophia->{nick}, $sophia->{usermode}));
        }

        for my $chan (keys %{$sophia->{channels}})
        {
            $sophia->yield(join => $chan);
        }

        $sophia->modulehandler->load_modules;

        return;
    }

    method _332 (@args)
    {
        my $heap = $args[HEAP - 1];
        my $sophia = $heap->{sophia};

        my $channel_data = $args[ARG2 - 1];
        my $channel = lc $channel_data->[0];
        my $topic   = $channel_data->[1];

        $sophia->{channel_topics}->{$channel} = $topic;

        return;
    }

    method _903 (@args)
    {
        my $heap = $args[HEAP - 1];
        my $sophia = $heap->{sophia};
        $sophia->is_authenticated(TRUE);

        Protocol::IRC::Response->_cap_end(@args);
        return;
    }

    method _904 (@args)
    {
        Protocol::IRC::Response->_cap_end(@args);
        return;
    }

    method _905 (@args)
    {
        Protocol::IRC::Response->_cap_end(@args);
        return;
    }

    method _906 (@args)
    {
        Protocol::IRC::Response->_cap_end(@args);
        return;
    }

    method _907 (@args)
    {
        Protocol::IRC::Response->_cap_end(@args);
        return;
    }

    method _authenticate (@args)
    {
        my $heap = $args[HEAP - 1];
        my $sophia = $heap->{sophia};

        my $sasl = join "\0", $sophia->nick, $sophia->username, $sophia->password;
        $sasl = encode_base64($sasl, '');

        if (!$sasl)
        {
            $sophia->yield(quote => 'AUTHENTICATE +');
            return;
        }

        while (length $sasl >= 400)
        {
            my $sub_sasl = substr $sasl, 0, 400, '';
            $sophia->yield(quote => 'AUTHENTICATE ' . $sub_sasl);
        }

        if ($sasl)
        {
            $sophia->yield(quote => 'AUTHENTICATE ' . $sasl);
        }
        else
        {
            $sophia->yield(quote => 'AUTHENTICATE +');
        }

        return;
    }

    method _cap (@args)
    {
        my $heap = $args[HEAP - 1];
        my $sophia = $heap->{sophia};

        if (!$sophia->usesasl || $sophia->is_connected)
        {
            return;
        }

        my ($key, $value) = @args[ARG0 - 1, ARG1 - 1];

        if ($key eq 'LS')
        {
            my $raw = '';
            $raw .= ' multi-prefix' if $value =~ /multi-prefix/i;
            $raw .= ' sasl' if $value =~ /sasl/i;
            $raw =~ s/^ //;

            if (!$raw)
            {
                $sophia->yield(quote => 'CAP END');
            }
            else
            {
                $sophia->yield(quote => 'CAP REQ :' . $raw);
            }
        }
        elsif ($key eq 'ACK')
        {
            if ($value =~ /sasl/i)
            {
                $sophia->yield(quote => 'AUTHENTICATE PLAIN');
            }
            else
            {
                $sophia->yield(quote => 'CAP END');
            }
        }
        elsif ($key eq 'NAK')
        {
            $sophia->yield(quote => 'CAP END');
        }

        return;
    }

    method _cap_end (@args)
    {
        my $heap = $args[HEAP - 1];
        my $sophia = $heap->{sophia};
        $sophia->yield(quote => 'CAP END');
        return;
    }

    method _connected (@args)
    {
        my $heap = $args[HEAP - 1];
        my $sophia = $heap->{sophia};

        if ($sophia->usesasl)
        {
            $sophia->yield(quote => 'CAP LS');
            $sophia->yield(quote => sprintf('NICK %s', $sophia->{nick}));
            $sophia->yield(quote => sprintf('USER %s %s * :%s', $sophia->username, 8, $sophia->realname));
        }

        return;
    }

    method _default (@args)
    {
        my ($event, $args) = @args[ARG0 - 1 .. $#args];

        # ignore irc_pings .. so annoying
        # unless verbose is used
        if ($event eq 'irc_ping' && !$sophia::CONFIGURATIONS{VERBOSE})
        {
            return;
        }

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

    method _privmsg (@args)
    {
        my $heap = $args[HEAP - 1];
        my $sophia = $heap->{sophia};

        my $event = Protocol::IRC::Event::PrivateMessage->new(
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
        $sophia->process_event_command('public', $event);

        return;
    }

    method _shutdown (@args)
    {
        return;
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
        return;
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
        return;
    }

    method _topic (@args)
    {
        my ($heap, $chan, $topic) = @args[HEAP - 1, ARG1 - 1, ARG2 - 1];
        $chan = lc $chan;

        my $sophia = $heap->{sophia};
        $sophia->{channel_topics}->{$chan} = $topic;

        return;
    }
}
