use strict;
use warnings;

sophia_module_add('sophia.part', '2.0', \&init_sophia_part, \&deinit_sophia_part);

sub init_sophia_part {
    sophia_command_add('sophia.part', \&sophia_part, 'Parts one or more channels.', '', SOPHIA_ACL_MASTER);
    sophia_event_privmsg_hook('sophia.part', \&sophia_part, 'Parts one or more channels.', '', SOPHIA_ACL_MASTER);

    return 1;
}

sub deinit_sophia_part {
    delete_sub 'init_sophia_part';
    delete_sub 'sophia_part';
    sophia_command_del 'sophia.part';
    sophia_event_privmsg_dehook 'sophia.part';
    delete_sub 'deinit_sophia_part';
}

sub sophia_part {
    my ($args, $target) = @_;
    my ($who, $where, $content) = ($args->[ARG0], $args->[ARG1], $args->[ARG2]);

    my $sophia = ${$args->[HEAP]->{sophia}};
    my @parts = split / /, $content;
    shift @parts;

    my $parted = 0;
    my $chans = sophia_cache_load('sophia_main', 'channels');
    for (@parts) {
        if (length) {
            sophia_log('sophia', sprintf('Parting (%s) requested by: %s.', $_, $who));
            # remove this from listchans
            delete $chans->{$_};
            $sophia->yield( part => $_ );
            $parted = 1;
        }
    }

    unless ($parted || $target) {   # in case of privmsg, don't part
        sophia_log('sophia', sprintf('Parting (%s) requested by: %s.', $where->[0], $who));
        delete $chans->{$where->[0]};
        $sophia->yield( part => $where->[0] );
    }
}

1;
