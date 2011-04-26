use strict;
use warnings;

sophia_module_add('google.translate', '1.0', \&init_google_translate, \&deinit_google_translate);

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
    my $param = $_[0];
    my @args = @{$param};
    my ($where, $content) = @args[ARG1 .. ARG2];
    $content = substr $content, index($content, ' ') + 1;
    $content =~ s/^\s+//;

    my $lang = substr $content, 0, index($content, ' ');
    my $text = substr $content, index($content, ' ') + 1;

    $lang =~ s/ /+/g;
    $text =~ s/ /+/g;

    my $objHTTP = get_file_contents(\sprintf('http://ajax.googleapis.com/ajax/services/language/translate?v=1.0&q=%s&langpair=%s', $text, $lang));
    $objHTTP = ${$objHTTP};

    if ($objHTTP =~ m/{"translatedText":"([^"]+)"}/) {
        my $val = $1;
        $val =~ s/\\u0026/&/g;
        sophia_write( \$where->[0], \decode_entities($val) );
    }
}

1;
