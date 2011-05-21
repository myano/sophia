use strict;
use warnings;

sub trim {
    my @args = @_;
    map {
        $_ =~ s/^\s+//;
        $_ =~ s/\s+$//;
    } @args;
    return @args;
}

1;
