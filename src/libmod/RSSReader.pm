use strict;
use warnings;
use XML::FeedPP;

sub loadRSS {
    my $uri = $_[0];
    my $feed = XML::FeedPP::RSS->new($uri);
    $feed->normalize();
    return \$feed;
}
