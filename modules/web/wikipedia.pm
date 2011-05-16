use strict;
use warnings;

sophia_module_add('web.wikipedia', '1.0', \&init_web_wikipedia, \&deinit_web_wikipedia);

sub init_web_wikipedia {
    sophia_command_add('web.wiki', \&web_wikipedia, 'Provides wikipedia searching.', '');
    sophia_global_command_add('wiki', \&web_wikipedia, 'Provides wikipedia searching.', '');

    return 1;
}

sub deinit_web_wikipedia {
    delete_sub 'init_web_wikipedia';
    delete_sub 'web_wikipedia';
    sophia_command_del 'web.wiki';
    delete_sub 'deinit_web_wikipedia';
}

sub web_wikipedia {
    my $param = $_[0];
    my @args = @{$param};
    my ($where, $content) = @args[ARG1, ARG2];
    
    my $idx = index $content, ' ';
    return unless $idx > -1;

    $content = substr $content, $idx + 1;
    $content =~ s/ /+/g;
    $content =~ s/&/%26/g;

    my $response = curl_get(sprintf('http://en.wikipedia.org/w/api.php?action=opensearch&search=%s&limit=1&namespace=0&format=xml', $content));
    return unless $response;

    $idx = index $response, '<Description ';
    return unless $idx > -1;

    $idx = index $response, '>', $idx + 1;
    my $result = substr $response, $idx + 1, index($response, '</Description>', $idx) - $idx - 1;
    unless (length($result) > 2) {
        $result = '';
    }
    else {
        $result .= '   ';
    }

    $idx = index $response, '<Url ', $idx;
    $idx = index $response, '>', $idx + 1;
    $result .= 'Read: ' . substr($response, $idx + 1, index($response, '</Url>', $idx) - $idx - 1);

    my $sophia = ${$args[HEAP]->{sophia}};
    $sophia->yield(privmsg => $where->[0] => $result);
}

1;
