use MooseX::Declare;
use Method::Signatures::Modifiers;

class Protocol::IRC::Response
{
    use API::Log qw(:ALL);
    use Constants;
    use Data::Dumper;
    use MIME::Base64;
    use POE qw(Component::IRC);
    use Protocol::IRC::Event::PrivateMessage;
    use Protocol::IRC::Event::Public;

    method _001 (@args)
    {
        $self = __PACKAGE__;
        unshift @args, $self;

        my $heap = $args[HEAP];
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

        $self->toString(@args);
        return;
    }

    method _332 (@args)
    {
        $self = __PACKAGE__;
        unshift @args, $self;

        my $heap = $args[HEAP];
        my $sophia = $heap->{sophia};

        my $channel_data = $args[ARG2];
        my $channel = lc $channel_data->[0];
        my $topic   = $channel_data->[1];

        $sophia->{channel_topics}->{$channel} = $topic;

        $self->toString(@args);
        return;
    }

    method _903 (@args)
    {
        $self = __PACKAGE__;
        unshift @args, $self;

        my $heap = $args[HEAP];
        my $sophia = $heap->{sophia};
        $sophia->is_authenticated(TRUE);

        $self->_cap_end(@args);
        return;
    }

    method _904 (@args)
    {
        $self = __PACKAGE__;
        unshift @args, $self;
        $self->_cap_end(@args);
        return;
    }

    method _905 (@args)
    {
        $self = __PACKAGE__;
        unshift @args, $self;
        $self->_cap_end(@args);
        return;
    }

    method _906 (@args)
    {
        $self = __PACKAGE__;
        unshift @args, $self;
        $self->_cap_end(@args);
        return;
    }

    method _907 (@args)
    {
        $self = __PACKAGE__;
        unshift @args, $self;
        $self->_cap_end(@args);
        return;
    }

    method _authenticate (@args)
    {
        $self = __PACKAGE__;
        unshift @args, $self;

        my $heap = $args[HEAP];
        my $sophia = $heap->{sophia};

        my $sasl = join "\0", $sophia->nick, $sophia->nick, $sophia->password;
        $sasl = encode_base64($sasl, '');

        if (!$sasl)
        {
            $sophia->yield(quote => 'AUTHENTICATE +');
        }
        else
        {
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
        }

        $self->toString(@args);
        return;
    }

    method _cap (@args)
    {
        $self = __PACKAGE__;
        unshift @args, $self;

        my $heap = $args[HEAP];
        my $sophia = $heap->{sophia};

        if ($sophia->usesasl && !$sophia->is_connected)
        {
            my ($key, $value) = @args[ARG0, ARG1];

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
        }

        $self->toString(@args);
        return;
    }

    method _cap_end (@args)
    {
        # this method can be called via timer
        if (!$self)
        {
            $self = __PACKAGE__;
            unshift @args, $self;
        }

        my $heap = $args[HEAP];
        my $sophia = $heap->{sophia};
        $sophia->yield(quote => 'CAP END');
        $self->toString(@args);
        return;
    }

    method _connected (@args)
    {
        $self = __PACKAGE__;
        unshift @args, $self;
        my $heap = $args[HEAP];
        my $sophia = $heap->{sophia};

        if ($sophia->usesasl)
        {
            $args[KERNEL]->alarm(cap_end => time + 3);
            $sophia->yield(quote => 'CAP LS');
            $sophia->yield(quote => sprintf('NICK %s', $sophia->{nick}));
            $sophia->yield(quote => sprintf('USER %s %s * :%s', $sophia->username, 8, $sophia->realname));
        }

        $self->toString(@args);
        return;
    }

    method _default (@args)
    {
        $self = __PACKAGE__;
        unshift @args, $self;

        my ($event, $args) = @args[ARG0 .. $#args];

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
        $self = __PACKAGE__;
        unshift @args, $self;
        my $heap = $args[HEAP];
        my $sophia = $heap->{sophia};
        $sophia->yield('shutdown');
        $self->toString(@args);
        return;
    }

    method _error (@args)
    {
        $self = __PACKAGE__;
        unshift @args, $self;
        _log('sophia', $args[ARG0]);
        $self->toString(@args);
        return;
    }

    method _privmsg (@args)
    {
        $self = __PACKAGE__;
        unshift @args, $self;

        my $heap = $args[HEAP];
        my $sophia = $heap->{sophia};

        my $event = Protocol::IRC::Event::PrivateMessage->new(
            sophia          => $sophia,
            sender          => $args[ARG0],
            recipients      => $args[ARG1],
            message         => $args[ARG2],
        );

        # if user is authenticated to NickServ
        if (exists $args[ARG3])
        {
            $event->hasNickServAuth(TRUE);
            $event->isNickServAuth(TRUE);
        }

        $sophia->process_input($event);

        $self->toString(@args);
        return;
    }

    method _public (@args)
    {
        $self = __PACKAGE__;
        unshift @args, $self;

        my $heap = $args[HEAP];
        my $sophia = $heap->{sophia};

        my $event = Protocol::IRC::Event::Public->new(
            sophia          => $sophia,
            sender          => $args[ARG0],
            recipients      => $args[ARG1],
            message         => $args[ARG2],
        );

        # if user is authenticated to NickServ
        if (exists $args[ARG3])
        {
            $event->hasNickServAuth(TRUE);
            $event->isNickServAuth(TRUE);
        }

        $sophia->process_input($event);
        $sophia->process_event_command('public', $event);

        $self->toString(@args);
        return;
    }

    method _shutdown (@args)
    {
        $self = __PACKAGE__;
        unshift @args, $self;
        $self->toString(@args);
        return;
    }

    method _sigint (@args)
    {
        $self = __PACKAGE__;
        unshift @args, $self;

        my $heap = $args[HEAP];
        my $sophia = $heap->{sophia};
        $sophia->yield(quit => 'Shutting down ... ');

        $args[KERNEL]->sig_handled();

        $self->toString(@args);
        return;
    }

    method _socketerr (@args)
    {
        $self = __PACKAGE__;
        unshift @args, $self;
        error_log('sophia', 'Failed to connect: ' . $args[ARG0]);
        $self->toString(@args);
        return;
    }

    method _start (@args)
    {
        $self = __PACKAGE__;
        unshift @args, $self;

        my $kernel = $args[KERNEL];
        $kernel->sig(INT => 'sig_int');

        my $heap = $args[HEAP];
        my $sophia = $heap->{sophia};
        if (!$sophia)
        {
            error_log('sophia', "Unable to get sophia instance from heap (start): $!\n");
        }

        $sophia->yield(register => 'all');
        $sophia->yield(connect  => { });

        $self->toString(@args);
        return;
    }

    method _stop (@args)
    {
        $self = __PACKAGE__;
        unshift @args, $self;
        $self->toString(@args);
        return;
    }

    method _topic (@args)
    {
        $self = __PACKAGE__;
        unshift @args, $self;

        my ($heap, $chan, $topic) = @args[HEAP, ARG1, ARG2];
        $chan = lc $chan;

        my $sophia = $heap->{sophia};
        $sophia->{channel_topics}->{$chan} = $topic;

        $self->toString(@args);
        return;
    }

    method toString (@args)
    {
        my ($tag, @rest) = @args[4,10..12];

        my @output = ( "$tag: " );

        ARG: for my $arg (@rest)
        {
            if (ref $arg eq 'ARRAY')
            {
                push @output, '[' . join(',', @$arg) . ']';
                next ARG;
            }

            if ($arg)
            {
                push @output, "'$arg'";
            }
        }

        print join ' ', @output, "\n";
        return;
    }
}
