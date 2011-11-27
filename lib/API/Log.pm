package API::Log;
use strict;
use warnings;
use Carp qw(carp croak);
use Exporter;
use base qw(Exporter);

our @EXPORT_OK = qw(slog error_log warn_log);

sub slog {
    my ($logfile, $msg) = @_;

    # if $msg is empty, don't log
    if ($msg eq '') {
        return;
    }

    $logfile = lc $logfile;

    # if the var directory doesn't exist, create it
    if (!-d $sophia::BASE{VAR}) {
        mkdir $sophia::BASE{VAR}, 0644 or return;
    }

    my $direction = '>>';

    # if the log file doesn't exist, create it.
    if (!-e "$sophia::BASE{VAR}/$logfile.log") {
        $direction = '>';
    }

    open my $fh, '>>', "$sophia::BASE{VAR}/$logfile.log" or return;
    print {$fh} '(', scalar localtime time, ') ', $msg, "\n";
    close $fh;

    return 1;
}

sub error_log {
    my ($logfile, $msg) = @_;
    $msg = '[ERROR] ' . $msg;
    
    slog($logfile, $msg);
    croak $msg;

    return;
}

sub warn_log {
    my ($logfile, $msg) = @_;
    $msg = '[WARNING] ' . $msg;

    slog($logfile, $msg);
    carp $msg;

    return;
}

1;
