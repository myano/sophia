use strict;
use warnings;

sophia_module_add('web.urltitle', '1.0', \&init_web_urltitle, \&deinit_web_urltitle);

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

my $max_redirects = 10;
sub web_urltitle {
    my $param = $_[0];
    my @args = @{$param};
    my ($where, $content) = ($args[ARG1], $args[ARG2]);

    my $response = curl_get($content);
    return unless $response;

    open FILE, '> text.txt';
    print FILE "$response";
    close FILE;

    return if index($response, '<title>') == -1;

    my $start = index($response, '<title>') + 7;
    my $end = index($response, '</title>') - $start;
    my $title = substr $response, $start, $end;
    $title =~ s/^\s+//;
    $title =~ s/\n//;
    $title =~ s/\s{2,}/ /;
    sophia_write( \$where->[0], \decode_entities($title) );
}

1;
