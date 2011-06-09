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

1;
