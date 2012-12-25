use strict;
use warnings;
use feature 'switch';

sophia_module_add('web.main', '1.0', \&init_web_main, \&deinit_web_main);

sub init_web_main {
    return 1;
}

sub wot {
    my $uri = $_[0];
    my $target;

    $target = $uri if $uri !~ /\b(https?:\/\/[^ ]+)\b/xsmi;

    my $api_uri = 'http://api.mywot.com/0.4/public_query2?';
    $api_uri .= defined($target) ? 'target' : 'url';
    $api_uri .= '=' . (defined($target) ? $target : $uri);

    my $response = curl_get($api_uri);
    return unless $response;

    my $reputation = my $confidence = 0;
    my $count = 0;
    while ($response =~ /<application name="\d+" r="(\d+)" c="(\d+)"\/>/g)
    {
        $reputation += $1;
        $confidence += $2;
        $count ++;
    }

    my %wot = (
        'Reputation'    => 'Very Poor',
        'Confidence'    => '0/5',
    );

    if ($count > 0)
    {
        $reputation /= $count;
        $confidence /= $count;

        if ($reputation >= 80)
        {
            $wot{'Reputation'} = 'Excellent';
        }
        elsif ($reputation >= 60)
        {
            $wot{'Reputation'} = 'Good';
        }
        elsif ($reputation >= 40)
        {
            $wot{'Reputation'} = 'Unsatisfactory';
        }
        elsif ($reputation >= 20)
        {
            $wot{'Reputation'} = 'Poor';
        }

        if ($confidence >= 45)
        {
            $wot{'Confidence'} = '5/5';
        }
        elsif ($confidence >= 34)
        {
            $wot{'Confidence'} = '4/5';
        }
        elsif ($confidence >= 23)
        {
            $wot{'Confidence'} = '3/5';
        }
        elsif ($confidence >= 12)
        {
            $wot{'Confidence'} = '2/5';
        }
        elsif ($confidence >= 6)
        {
            $wot{'Confidence'} = '1/5';
        }
    }

    return \%wot;
}

sub deinit_web_main {
    delete_sub 'init_web_main';
    delete_sub 'deinit_web_main';
}

1;
