use strict;
use warnings;

sub sophia_log {
    my ($log, $err_msg) = @_;
    return unless $err_msg;

    $log = lc $log;
    unless ( -d "$Bin/../var" ) {
        mkdir "$Bin/../var", 0760 or return;
    }

    unless ( -e "$Bin/../var/$log.log" ) {
        open my $fh, '>', "$Bin/../var/$log.log" or return;
        close $fh;
    }
    open my $fh, '>>', "$Bin/../var/$log.log" or return;
    print {$fh} '(', scalar(localtime(time())), ') ', $err_msg, "\n";
    close $fh;
}

1;
