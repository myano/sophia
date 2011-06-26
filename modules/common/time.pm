use strict;
use warnings;

my %timezones = 
(
    'KST' => 9,
    'CADT' => 10.5,
    'EETDST' => 3,
    'MESZ' => 2,
    'WADT' => 9,
    'EET' => 2,
    'MST' => -7,
    'CDT' => -5,
    'WAST' => 8,
    'IST' => 5.5,
    'B' => 2,
    'MSK' => 3,
    'X' => -11,
    'MSD' => 4,
    'CETDST' => 2,
    'AST' => -4,
    'HKT' => 8,
    'JST' => 9,
    'CAST' => 9.5,
    'CET' => 1,
    'CEST' => 2,
    'EEST' => 3,
    'EAST' => 10,
    'METDST' => 2,
    'MDT' => -6,
    'A' => 1,
    'UTC' => 0,
    'ADT' => -3,
    'EST' => -5,
    'E' => 5,
    'D' => 4,
    'G' => 7,
    'F' => 6,
    'I' => 9,
    'H' => 8,
    'K' => 10,
    'PDT' => -7,
    'M' => 12,
    'L' => 11,
    'O' => -2,
    'MEST' => 2,
    'Q' => -4,
    'P' => -3,
    'S' => -6,
    'R' => -5,
    'U' => -8,
    'T' => -7,
    'W' => -10,
    'WET' => 0,
    'Y' => -12,
    'CST' => -6,
    'EADT' => 11,
    'Z' => 0,
    'GMT' => 0,
    'WETDST' => 1,
    'C' => 3,
    'WEST' => 1,
    'MET' => 1,
    'N' => -1,
    'V' => -9,
    'EDT' => -4,
    'UT' => 0,
    'PST' => -8,
    'MEZ' => 1,
    'BST' => 1,
    'ACS' => 9.5,
    'ATL' => -4,
    'ALA' => -9,
    'HAW' => -10,
    'AKDT' => -8,
    'AKST' => -9, 
    'BDST' => 2,
    'NDT' => -2.5, 
    'BRST' => -2, 
    'ADT' => -3, 
    'MDT' => -6, 
    'PDT' => -7, 
    'YDT' => -8, 
    'HDT' => -9, 
    'BST' => 1, 
    'MEST' => 2, 
    'SST' => 2, 
    'FST' => 2, 
    'CEST' => 2, 
    'EEST' => 3, 
    'WADT' => 8, 
    'KDT' => 10, 
    'EADT' => 13, 
    'NZD' => 13, 
    'NZDT' => 13, 
    'GMT' => 0, 
    'UT' => 0, 
    'UTC' => 0, 
    'WET' => 0, 
    'WAT' => -1, 
    'AT' => -2, 
    'FNT' => -2, 
    'BRT' => -3, 
    'MNT' => -4, 
    'EWT' => -4, 
    'AST' => -4, 
    'ACT' => -5, 
    'MST' => -7, 
    'YST' => -9, 
    'HST' => -10, 
    'CAT' => -10, 
    'AHST' => -10, 
    'NT' => -11, 
    'IDLW' => -12, 
    'CET' => 1, 
    'MEZ' => 1, 
    'ECT' => 1, 
    'MET' => 1, 
    'MEWT' => 1, 
    'SWT' => 1, 
    'SET' => 1, 
    'FWT' => 1, 
    'EET' => 2, 
    'UKR' => 2, 
    'BT' => 3, 
    'ZP4' => 4, 
    'ZP5' => 5, 
    'ZP6' => 6, 
    'WST' => 8, 
    'HKT' => 8, 
    'CCT' => 8, 
    'JST' => 9, 
    'KST' => 9, 
    'EAST' => 10, 
    'GST' => 10, 
    'NZT' => 12, 
    'NZST' => 12, 
    'IDLE' => 12,
    'ACDT' => 10.5, 
    'ACST' => 9.5, 
    'ADT' => 3, 
    'AEDT' => 11,
    'AEST' => 10,
    'AHDT' => 9, 
    'AHST' => 10, 
    'AST' => 4, 
    'AT' => 2, 
    'AWDT' => -9, 
    'AWST' => -8, 
    'BAT' => -3, 
    'BDST' => -2, 
    'BET' => 11, 
    'BST' => -1, 
    'BT' => -3, 
    'BZT2' => 3, 
    'CADT' => -10.5, 
    'CAST' => -9.5, 
    'CAT' => 10, 
    'CCT' => -8, 
    'CED' => -2, 
    'CET' => -1, 
    'EAST' => -10, 
    'EED' => -3, 
    'EET' => -2, 
    'EEST' => -3, 
    'FST' => -2, 
    'FWT' => -1, 
    'GMT' => 0, 
    'GST' => -10, 
    'HDT' => 9, 
    'HST' => 10, 
    'IDLE' => -12, 
    'IDLW' => 12, 
    'IT' => -3.5, 
    'JST' => -9, 
    'JT' => -7, 
    'KST' => -9, 
    'MDT' => 6, 
    'MED' => -2, 
    'MET' => -1, 
    'MEST' => -2, 
    'MEWT' => -1, 
    'MST' => 7, 
    'MT' => -8, 
    'NDT' => 2.5, 
    'NFT' => 3.5, 
    'NT' => 11, 
    'NST' => -6.5, 
    'NZ' => -11, 
    'NZST' => -12, 
    'NZDT' => -13, 
    'NZT' => -12, 
    'ROK' => -9, 
    'SAD' => -10, 
    'SAST' => -9, 
    'SAT' => -9, 
    'SDT' => -10, 
    'SST' => -2, 
    'SWT' => -1, 
    'USZ3' => -4, 
    'USZ4' => -5, 
    'USZ5' => -6, 
    'USZ6' => -7, 
    'UT' => 0, 
    'UTC' => 0, 
    'UZ10' => -11, 
    'WAT' => 1, 
    'WET' => 0, 
    'WST' => -8, 
    'YDT' => 8, 
    'YST' => 9, 
    'ZP4' => -4, 
    'ZP5' => -5, 
    'ZP6' => -6,
    'AEST' => 10, 
    'AEDT' => 11
);

sophia_module_add('common.time', '1.0', \&init_common_time, \&deinit_common_time);

sub init_common_time {
    sophia_command_add('common.time', \&common_time, 'Print the current time.', 'Prints the current time. If no parameters are given it prints GMT.');

    return 1;
}

sub deinit_common_time {
    delete_sub 'init_common_time';
    delete_sub 'common_time';
    sophia_command_del 'common.time';
    delete_sub 'deinit_common_time';
}

sub common_time {
    my $args = $_[0];
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);


    my $idx = index $content, ' ';
    return if $idx == -1;
    $content = substr $content, $idx + 1;
    $content =~ s/\A\s+//;
    return if !$content;

    my $sophia = $args->[HEAP]->{sophia};

    # if we have this timezone, show the time
    if (defined(my $offset = $timezones{uc $content})) {
        $sophia->yield(privmsg => $where->[0] => sprintf('%s %s', scalar(gmtime(time() + $offset * 3600)), $content));
        return;
    }

    # try to perform a Google search of the data then
    $content =~ s/ /+/g;

    my $response = curl_get(sprintf('http://www.google.com/search?q=time+%s', $content));

    if (!$response || $response !~ /(<b>\d{1,2}:\d{1,2}(a|p)m<\/b>.*?<\/table>)/xsmi) {
        $sophia->yield(privmsg => $where->[0] => sprintf('%s GMT', scalar(gmtime(time()))));
        return;
    }

    my $result = $1;

    # strip new lines
    $result =~ s/\r\n|\n//xsmg;

    # strip html tags
    $result =~ s/<\/?[^>]+>//xsmg;

    $sophia->yield(privmsg => $where->[0] => $result);
}

1;
