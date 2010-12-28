use strict;
use warnings;

sub trigger_error {
    my ($log, $err_msg) = @_;
    $log = lc $log;
    sophia_log($log, '[ERROR] ' . $err_msg);
    croak '[ERROR] ' . $err_msg;
}

sub trigger_warning {
    my ($log, $warn_msg) = @_;
    $log = lc $log;
    sophia_log($log, '[WARNING] ' . $warn_msg);
    carp '[WARNING] ' . $warn_msg;
}

sub sophia_log {
    my ($log, $err_msg) = @_;
    $log = lc $log;
    unless ( -d "$Bin/../var" ) {
        mkdir "$Bin/../var", 0760 or return;
    }
    unless ( -e "$Bin/../var/$log.log" ) {
        open LOG, "> $Bin/../var/$log.log" or return;
        close LOG;
    }
    open LOG, ">> $Bin/../var/$log.log" or return;
    print LOG '(' . scalar(localtime(time())).') ' . $err_msg . "\n";
    close LOG;
}

1;
