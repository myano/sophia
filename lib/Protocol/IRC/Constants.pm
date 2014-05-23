use MooseX::Declare;
use Method::Signatures::Modifiers;

class Protocol::IRC::Constants
{
    use Exporter;
    use base qw(Exporter);

    our @EXPORT_OK = qw(
        IRC_MESSAGE_LENGTH
        
        IRC_TEXT_FORMAT_BOLD
        IRC_TEXT_FORMAT_FIXED
        IRC_TEXT_FORMAT_ITALIC
        IRC_TEXT_FORMAT_REVERSE
        IRC_TEXT_FORMAT_UNDERLINE

        IRC_TEXT_COLOR_BLACK
        IRC_TEXT_COLOR_BROWN
        IRC_TEXT_COLOR_CYAN
        IRC_TEXT_COLOR_DARKBLUE
        IRC_TEXT_COLOR_DARKGREEN
        IRC_TEXT_COLOR_DARKGREY
        IRC_TEXT_COLOR_LIGHTBLUE
        IRC_TEXT_COLOR_LIGHTGREEN
        IRC_TEXT_COLOR_LIGHTGREY
        IRC_TEXT_COLOR_MAGENTA
        IRC_TEXT_COLOR_ORANGE
        IRC_TEXT_COLOR_PURPLE
        IRC_TEXT_COLOR_RED
        IRC_TEXT_COLOR_TEAL
        IRC_TEXT_COLOR_YELLOW
        IRC_TEXT_COLOR_WHITE
    );
    our @EXPORT = @EXPORT_OK;
    our %EXPORT_TAGS = (
        ALL     => \@EXPORT_OK,
    );

    use constant IRC_MESSAGE_LENGTH         => 400;

    use constant IRC_TEXT_FORMAT_BOLD       => "\x02";
    use constant IRC_TEXT_FORMAT_FIXED      => "\x11";
    use constant IRC_TEXT_FORMAT_ITALIC     => "\x1d";
    use constant IRC_TEXT_FORMAT_REVERSE    => "\x16";
    use constant IRC_TEXT_FORMAT_UNDERLINE  => "\x1f";

    use constant IRC_TEXT_COLOR_BLACK       => "\x0301";
    use constant IRC_TEXT_COLOR_BROWN       => "\x0305";
    use constant IRC_TEXT_COLOR_CYAN        => "\x0311";
    use constant IRC_TEXT_COLOR_DARKBLUE    => "\x0302";
    use constant IRC_TEXT_COLOR_DARKGREEN   => "\x0303";
    use constant IRC_TEXT_COLOR_DARKGREY    => "\x0314";
    use constant IRC_TEXT_COLOR_LIGHTBLUE   => "\x0312";
    use constant IRC_TEXT_COLOR_LIGHTGREEN  => "\x0309";
    use constant IRC_TEXT_COLOR_LIGHTGREY   => "\x0315";
    use constant IRC_TEXT_COLOR_MAGENTA     => "\x0313";
    use constant IRC_TEXT_COLOR_ORANGE      => "\x0307";
    use constant IRC_TEXT_COLOR_PURPLE      => "\x0306";
    use constant IRC_TEXT_COLOR_RED         => "\x0304";
    use constant IRC_TEXT_COLOR_TEAL        => "\x0310";
    use constant IRC_TEXT_COLOR_YELLOW      => "\x0308";
    use constant IRC_TEXT_COLOR_WHITE       => "\x0300";
}
