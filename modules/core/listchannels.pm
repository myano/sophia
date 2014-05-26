use MooseX::Declare;
use Method::Signatures::Modifiers;

class core::listchannels with API::Module
{
    use API::Log qw(:ALL);

    has 'name'  => (
        default => 'core::listchannels',
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
        my @channels = sort { uc $a cmp uc $b } keys %{$event->sophia->channels};
        my $channel_list = join ' ', @channels;

        $event->reply($channel_list);
    }
}
