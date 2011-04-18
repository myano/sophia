use strict;
use warnings;
use HTML::Entities;

sub sophia_kick {
    my ($chan, $nick, $text) = @_;
    $chan = ${$chan};
    $nick = ${$nick};
    $text = ${$text};
    return unless $chan && $nick;

    $text = '' unless $text;

    $sophia::sophia->yield( kick => $chan => $nick => $text );
}

sub sophia_write {
    my ($chans, $text) = @_;
    my @channels;
    my @output;

    if (ref($chans) eq "SCALAR") {
        push @channels, $$chans;
    }
    elsif (ref($chans) eq "ARRAY") {
        @channels = @$chans;
    }

    if (ref($text) eq "SCALAR") {
        push @output, $$text;
    }
    elsif (ref($text) eq "ARRAY") {
        @output = @$text;
    }

    for my $chan (@channels) {
        $sophia::sophia->yield(privmsg => $chan => decode_entities($_)) for @output;
    }
}

1;
