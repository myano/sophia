use MooseX::Declare;
use Method::Signatures::Modifiers;

class core::part
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

    method run ($event)
    {
        my @channels = split(' ', $event->content);

        for my $channel (@channels)
        {
            _log('sophia', sprintf('Parting channel (%s) as requested by %s.', $channel, $event->sender));

            delete $event->sophia->channels->{$channel};
            $event->sophia->yield(part => $channel);
        }
    }
}
