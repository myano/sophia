use strict;
use warnings;

sophia_module_add('sophia.part', '1.0', \&init_sophia_part, \&deinit_sophia_part);

sub init_sophia_part {
    sophia_global_command_add('part', \&sophia_part, 'Parts one or more channels.', '');
    sophia_event_privmsg_hook('sophia.part', \&sophia_part, 'Parts one or more channels.', '');

    return 1;
}

sub deinit_sophia_part {
    delete_sub 'init_sophia_part';
    delete_sub 'sophia_part';
    sophia_global_command_del 'part';
    sophia_event_privmsg_dehook 'sophia.part';
    delete_sub 'deinit_sophia_part';
}

sub sophia_part {
    my ($args, $target) = @_;
    my @args = @{$args};
    my ($heap, $who, $where, $content) = @args[HEAP, ARG0 .. ARG2];

    my $perms = sophia_get_host_perms($who);
    return unless $perms & SOPHIA_ACL_FOUNDER;

    my $sophia = ${$heap->{sophia}};
    my @parts = split / /, $content;
    shift @parts;

    my $parted = 0;
    for (@parts) {
        if (length) {
            sophia_log('sophia', sprintf('Parting (%s) requested by: %s.', $_, $who));
            $sophia->yield( part => $_ );
            $parted = 1;
        }
    }

    unless ($parted || $target) {   # in case of privmsg, don't part
        sophia_log('sophia', sprintf('Parting (%s) requested by: %s.', $where->[0], $who));
        $sophia->yield( part => $where->[0] );
    }
}

1;
