use MooseX::Declare;
use Method::Signatures::Modifiers;

class core::part with API::Module
{
    use API::Log qw(:ALL);

    has 'name'  => (
        default => 'core::part',
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

        # if no channels are given, then part from recipients
        unless (@channels)
        {
            @channels = @{$event->recipients};
        }

        for my $channel (@channels)
        {
            _log('sophia', sprintf('Parting channel (%s) as requested by %s.', $channel, $event->sender));

            delete $event->sophia->channels->{$channel};
            $event->sophia->yield(part => $channel);
        }
    }
}
