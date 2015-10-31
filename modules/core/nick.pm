use MooseX::Declare;
use Method::Signatures::Modifiers;

class core::nick with API::Module
{
    use API::Log qw(:ALL);

    has 'name'  => (
        default => 'core::nick',
        is      => 'ro',
        isa     => 'Str',
    );

    has 'version'   => (
        default     => '1.0',
        is          => 'ro',
        isa         => 'Str',
    );

    method access ($event)
    {
        return $event->is_sender_operator();
    }

    method run ($event)
    {
        my ($nick, @rest) = split(' ', $event->content);

        _log('sophia', sprintf('Changing nick to %s as requested by %s.', $nick,
                $event->sender));
        $event->sophia->yield(nick => $nick);

        $event->sophia->nick = $nick;
    }
}
