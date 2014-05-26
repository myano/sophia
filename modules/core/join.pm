use MooseX::Declare;
use Method::Signatures::Modifiers;

class core::join with API::Module
{
    use API::Log qw(:ALL);

    has 'name'  => (
        default => 'core::join',
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
        my @channels = split(' ', $event->content);

        for my $channel (@channels)
        {
            _log('sophia', sprintf('Joining channel (%s) as requested by %s.', $channel, $event->sender));

            $event->sophia->channels->{$channel} = 1;
            $event->sophia->yield(join => $channel);
        }
    }
}
