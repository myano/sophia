use strict;
use warnings;

sub trim {
    my @args = @_;
    map {
        $_ =~ s/\A\s+//;
        $_ =~ s/\s+\z//;
    } @args;
    return @args;
}

sub irc_split_lines {
    my @messages = (shift =~ m/.{0,300}[^ ]* ?/g);
    return \@messages;
}

1;
