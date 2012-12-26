use MooseX::Declare;
use Method::Signatures::Modifiers;

class API::Log
{
    use Carp qw(carp croak);
    use Exporter;
    use base qw(Exporter);

    our @EXPORT_OK = qw(_log error_log warn_log);
    our %EXPORT_TAGS = (
        ALL     => \@EXPORT_OK,
    );

    method _log
    {
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

        open my $fh, $direction, "$sophia::BASE{VAR}/$logfile.log" or return;
        print {$fh} '(', scalar localtime time, ') ', $msg, "\n";
        close $fh;

        return;
    }

    method error_log
    {
        my ($logfile, $msg) = @_;
        $msg = '[ERROR] ' . $msg;
        
        $self->_log($logfile, $msg);
        croak $msg;

        return;
    }

    method warn_log {
        my ($logfile, $msg) = @_;
        $msg = '[WARNING] ' . $msg;

        $self->_log($logfile, $msg);
        carp $msg;

        return;
    }
}
