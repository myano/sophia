use MooseX::Declare;
use Method::Signatures::Modifiers;

class google::calculator with API::Module
{
    use HTML::Entities;
    use URI::Escape;
    use Util::Curl;
    use Util::String;

    has 'name'  => (
        default => 'google::calculator',
        is      => 'ro',
        isa     => 'Str',
    );

    has 'version'   => (
        default     => '1.0',
        is          => 'ro',
        isa         => 'Str',
    );

    method run ($event)
    {
        my $result = $self->calculate($event->content);
        
        unless ($result && $result->{lhs} && $result->{rhs})
        {
            $event->reply('Unable to compute "' . $event->content . '".');
            return;
        }

        $event->reply( sprintf('%s = %s', $result->{lhs}, $result->{rhs}) );
    }

    method calculate ($expr)
    {
        my $response = Util::Curl->get(sprintf('https://www.google.com/search?gbv=1&q=%s', uri_escape($expr)));
        return unless $response;

        my %result = (
            lhs     => '',
            rhs     => '',
        );

        if ($response =~ m#<h2\s+class="r"[^>]*>(.+?)</h2>#xsmi)
        {
            my $answer = $1;
            my $equals = index($answer, '=');
            return if $equals == -1;

            if ($equals > -1)
            {
                my $lhs = substr($answer, 0, $equals);
                my $rhs = substr($answer, $equals + 1);

                $lhs = Util::String->trim($lhs);
                $rhs = Util::String->trim($rhs);

                $lhs = HTML::Entities::decode($lhs);
                $rhs = HTML::Entities::decode($rhs);

                $result{lhs} = $lhs;
                $result{rhs} = $rhs;
            }
        }

        return \%result;
    }
}
