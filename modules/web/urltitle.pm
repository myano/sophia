use strict;
use warnings;

sophia_module_add('web.urltitle', '2.0', \&init_web_urltitle, \&deinit_web_urltitle);

sub init_web_urltitle {
    sophia_event_public_hook('web.urltitle', \&web_urltitle, 'Displays the title for the posted URL.', '');

    return 1;
}

sub deinit_web_urltitle {
    delete_sub 'init_web_urltitle';
    delete_sub 'web_urltitle';
    sophia_event_public_dehook 'web.urltitle';
    delete_sub 'deinit_web_urltitle';
}

sub web_urltitle {
    my $args = $_[0];
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);

    my $response = curl_get($content);
    return unless $response;

    if ($response =~ m#<title[^>]*>(.+?)</title>#xsmi) {
        my $title = $1;
        my $sophia = ${$args->[HEAP]->{sophia}};
        $title =~ s/\s{2,}/ /g;
        $sophia->yield(privmsg => $where->[0] => decode_entities($title));
    }
}

1;
