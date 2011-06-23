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
    my ($who, $where, $content) = ($args->[ARG0], $args->[ARG1], $args->[ARG2]);
    
    return if $who =~ /cia\.atheme\.org/;  # ignore CIA bot commit bit.ly lookups.
    return if $content !~ /\b(https?:\/\/[^ ]+)\b/xsmi;

    my $response = curl_get($1);
    return unless $response;

    if ($response =~ m#<title[^>]*>(.+?)</title>#xsmi) {
        my $title = $1;

        $title =~ s/\r\n|\n//g;
        $title =~ s/^\s+//g;
        $title =~ s/\s{2,}/ /g;

        $title = '&laquo; ' . $title . ' &raquo;';
        $title = decode_entities($title);
        
        my $sophia = $args->[HEAP]->{sophia};
        $sophia->yield(privmsg => $where->[0] => $title);
    }
}

1;
