use strict;
use warnings;

sophia_module_add('google.translate', '2.0', \&init_google_translate, \&deinit_google_translate);

sub init_google_translate {
    sophia_command_add('google.translate', \&google_translate, 'Utilize Google for translations.', '');

    return 1;
}

sub deinit_google_translate {
    delete_sub 'init_google_translate';
    delete_sub 'google_translate';
    sophia_command_del 'google.translate';
    delete_sub 'deinit_google_translate';
}

sub google_translate {
    my $args = $_[0];
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    $content = substr $content, index($content, ' ') + 1;
    $content =~ s/\A\s+//;

    return unless $content;

    my $lang = substr $content, 0, index($content, ' ');
    my $text = substr $content, index($content, ' ') + 1;

    $lang =~ s/ /+/g;
    $text =~ s/ /+/g;

    my $response = curl_get(sprintf('http://ajax.googleapis.com/ajax/services/language/translate?v=1.0&q=%s&langpair=%s', $text, $lang));
    return unless $response;

    my $sophia = $args->[HEAP]->{sophia};
    if ($response =~ m/{"translatedText":"([^"]+)"}/) {
        my $val = $1;
        $val =~ s/\\u0026/&/g;
        $sophia->yield(privmsg => $where->[0] => decode_entities($val));
    }
}

1;
