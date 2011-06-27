use strict;
use warnings;

sophia_module_add('web.tinyurl', '2.0', \&init_web_tinyurl, \&deinit_web_tinyurl);

sub init_web_tinyurl {
    sophia_command_add('web.tinyurl', \&web_tinyurl, 'Creates a tinyurl redirector link.', '');

    return 1;
}

sub deinit_web_tinyurl {
    delete_sub 'init_web_tinyurl';
    delete_sub 'web_tinyurl';
    sophia_command_del 'web.tinyurl';
    delete_sub 'deinit_web_tinyurl';
}

sub web_tinyurl {
    my $args = $_[0];
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);

    my $idx = index $content, ' ';
    $content = $idx > -1 ? substr($content, $idx + 1) : '';

    my $uri = "http://tinyurl.com/api-create.php?url=$content";
    my $response = curl_get($uri);
    return unless $response;

    my $sophia = $args->[HEAP]->{sophia};
    $sophia->yield(privmsg => $where->[0] => $response );
}

1;
