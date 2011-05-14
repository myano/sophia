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

    my $objXML = get_file_contents( \sprintf('http://en.wikipedia.org/w/api.php?action=opensearch&search=%s&limit=1&namespace=0&format=xml', $content) );
    $objXML = ${$objXML};
    return unless $objXML;

    $idx = index $objXML, '<Description ';
    return unless $idx > -1;

    $idx = index $objXML, '>', $idx + 1;
    my $result = substr $objXML, $idx + 1, index($objXML, '</Description>', $idx) - $idx - 1;
    unless (length($result) > 2) {
        $result = '';
    }
    else {
        $result .= '   ';
    }

    $idx = index $objXML, '<Url ', $idx;
    $idx = index $objXML, '>', $idx + 1;
    $result .= 'Read: ' . substr($objXML, $idx + 1, index($objXML, '</Url>', $idx) - $idx - 1);

    sophia_write( \$where->[0], \$result );
}

1;
