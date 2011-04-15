use strict;
use warnings;
use HTML::Entities;
use Encode;

sub sophia_write {
    my ($chans, $text) = @_;
    my @channels = @$chans;
    foreach my $chan (@channels) {
        $sophia::sophia->yield(privmsg => $chan => encode_utf8(decode_entities($text)));
    }
}

1;
