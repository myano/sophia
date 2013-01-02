use MooseX::Declare;
use Method::Signatures::Modifiers;

class Protocol::IRC::Constants
{
    use Exporter;
    use base qw(Exporter);

    our @EXPORT_OK = qw(IRC_MESSAGE_LENGTH);
    our @EXPORT = @EXPORT_OK;
    our %EXPORT_TAGS = (
        ALL     => \@EXPORT_OK,
    );

    use constant IRC_MESSAGE_LENGTH     => 300;
}
