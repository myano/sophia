use MooseX::Declare;
use Method::Signatures::Modifiers;

class Constants
{
    use Exporter;
    use base qw(Exporter);

    our @EXPORT_OK = qw(TRUE FALSE true false);
    our @EXPORT    = @EXPORT_OK;
    our %EXPORT_TAGS = (
        ALL     => \@EXPORT_OK,
    );

    use constant TRUE       => 1;
    use constant FALSE      => 0;
    use constant true       => 1;
    use constant false      => 0;
}
