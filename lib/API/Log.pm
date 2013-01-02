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

    method _log (@args)
    {
        my ($logfile, $msg) = ($self, shift);

        # if $msg is empty, don't log
        if ($msg eq '')
        {
            return;
        }

        $logfile = lc $logfile;

        # if the var directory doesn't exist, create it
        if (!-d $sophia::BASE{VAR})
        {
            mkdir $sophia::BASE{VAR}, 0644 or return;
        }

        open my $fh, '>>', "$sophia::BASE{VAR}/$logfile.log"
            or croak "Cannot write to $sophia::BASE{VAR}/$logfile.log: $!";
        print {$fh} '(', scalar localtime time, ') ', $msg, "\n";
        close $fh;

        return;
    }

    method error_log (@args)
    {
        my ($logfile, $msg) = ($self, shift);

        $msg = '[ERROR] ' . $msg;
        
        $self->_log($logfile, $msg);
        croak $msg;

        return;
    }

    method warn_log (@args)
    {
        my ($logfile, $msg) = ($self, shift);

        $msg = '[WARNING] ' . $msg;

        $self->_log($logfile, $msg);
        carp $msg;

        return;
    }
}
