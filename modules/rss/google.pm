use strict;
use warnings;
use feature 'switch';

my $Google_Timer = 60 * 30;   # in seconds
my $Google_MAXCOUNT = 3;

# do not edit below this line unless you know what you're doing.
my $Google_LastDate = undef;
my %Google_Channels = ('#sophia');
my $Google_IsActive = 0;

sophia_module_add("rss.google", "1.0", \&init_rss_google, \&deinit_rss_google);

sub init_rss_google {
    sophia_event_privmsg_hook('rss.google', \&rss_google, 'Start or stop Google RSS feeds.', '', SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP);

    return 1;
}

sub deinit_rss_google {
    delete_sub 'init_rss_google';
    delete_sub 'rss_google';
    delete_sub 'rss_google_main';
    delete_sub 'rss_google_timer';
    delete_sub 'rss_google_unescape';
    delete_sub 'rss_google_reltime_seconds';
    sophia_timer_del 'rss_google_timer';
    sophia_event_privmsg_dehook 'rss.google';
    delete_sub 'deinit_rss_google';
}

sub rss_google_unescape {
    my $str = $_[0];
    $str =~ s/&amp;/&/g;
    return decode_entities($str);
}

sub rss_google_reltime_seconds {
    my ($time, $reltime) = @_;

    if ($reltime =~ /(\d+) seconds? ago/)     { return $time - $1; }
    if ($reltime =~ /(\d+) minutes? ago/)     { return $time - $1 * 60; }
    if ($reltime =~ /(\d+) hours? ago/)       { return $time - $1 * 3600; }

    return $time - 24 * 3600;
}

sub rss_google {
    my ($args, $target) = @_;
    my $content = $args->[ARG2];
    my $sophia = $args->[HEAP]->{sophia};

    my @opts = split /\s+/, $content;
    return if $#opts < 1;

    given (lc $opts[1]) {
        when ('add') {
            if ($opts[2]) {
                my $chan = lc $opts[2];

                if ($Google_Channels{$chan}) {
                    $sophia->yield(privmsg => $target => sprintf('Channel %s is already on the list.', $chan));
                    return;
                }

                $Google_Channels{$chan} = 1;
                $sophia->yield(privmsg => $target => sprintf('Channel %s added.', $chan));
            }
        }
        when ('clear') {
            delete $Google_Channels{lc $_} for keys %Google_Channels;
            $sophia->yield(privmsg => $target => 'Cleared');
        }
        when ('del') {
            if ($opts[2]) {
                my $chan = lc $opts[2];

                if (!$Google_Channels{$chan}) {
                    $sophia->yield(privmsg => $target => sprintf('Channel %s is not on the list.', $chan));
                    return;
                }

                delete $Google_Channels{$chan};
                $sophia->yield(privmsg => $target => sprintf('Channel %s deleted.', $chan));
            }
        }
        when ('listchans') {
            my $chans = join ' ', keys %Google_Channels;
            my @messages = ($chans =~ m/.{0,300}[^ ] ?/g);
            $sophia->yield(privmsg => $target => $_) for @messages;
        }
        when ('start')  {
            if (!$Google_IsActive) {
                $args->[KERNEL]->alarm( 'rss_google_timer' => time() );
                $Google_IsActive = 1;
                $sophia->yield(privmsg => $target => 'Google News feed starting ... ');
                return;
            }

            $sophia->yield(privmsg => $target => 'Google News feed is already running.');
        }
        when ('stop') {
            if ($Google_IsActive) {
                $args->[KERNEL]->alarm( 'rss_google_timer' );
                $Google_IsActive = 0;
                $sophia->yield(privmsg => $target => 'Google News feed stopping ... ');
                return;
            }

            $sophia->yield(privmsg => $target => 'Google News feed is not running.');
        }
    }
}

sub rss_google_main {
    # if there are no channels set, do nothing
    return if scalar(keys %Google_Channels) == 0;

    my $objXML = loadXML("http://www.google.com/ig/api?news");
    return if !$objXML;
    $objXML = ${$objXML};

    my @news;
    my ($url, $snippet, $source, $date);
    my $time = time;

    for ($objXML->findnodes('//news_entry')) {
        $date = $_->findnodes('./date')->[0]->getAttribute('data');
        $date = rss_google_reltime_seconds($time, $date);

        # if $Google_LastDate is defined and $date is not after it, ignore it
        next if defined($Google_LastDate) && $Google_LastDate > $date;

        $url = $_->findnodes('./url')->[0]->getAttribute('data');
        $snippet = $_->findnodes('./snippet')->[0]->getAttribute('data');
        $source = $_->findnodes('./source')->[0]->getAttribute('data');
        push @news, { url => $url, snippet => $snippet, source => $source, date => $date };
    }

    # if @news is empty, do nothing
    return if $#news == -1;

    # sort by time (ascending order)
    my @sorted_news = sort { $b->{date} <=> $a->{date} } @news;

    # store the latest time in $Google_LastDate
    $Google_LastDate = $sorted_news[0]->{date};

    # print the top 3 results
    my $sophia = $_[0]->[HEAP]->{sophia};
    my $count = $#sorted_news;
    $count = $Google_MAXCOUNT if $count > $Google_MAXCOUNT;

    for my $i (0..$count-1) {
        $sophia->yield(privmsg => $_ =>
            sprintf('%1$s%2$s:%1$s %3$s  %4$s', "\x02",
                $sorted_news[$i]->{source},
                rss_google_unescape($sorted_news[$i]->{snippet}),
                $sorted_news[$i]->{url}))
            for keys %Google_Channels;
    }
}

sub rss_google_timer {
    &rss_google_main(\@_) if @_;
    $_[KERNEL]->alarm( 'rss_google_timer' => time() + $Google_Timer );
}

1;
