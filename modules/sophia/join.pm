use strict;
use warnings;

sophia_module_add('sophia.join', '2.0', \&init_sophia_join, \&deinit_sophia_join);

sub init_sophia_join {
    sophia_global_command_add('join', \&sophia_join, 'Joins one or more channels.', '', SOPHIA_ACL_FOUNDER);
    sophia_event_privmsg_hook('sophia.join', \&sophia_join, 'Joins one or more channels.', '', SOPHIA_ACL_FOUNDER);

    return 1;
}

sub deinit_sophia_join {
    delete_sub 'init_sophia_join';
    delete_sub 'sophia_join';
    sophia_global_command_del 'join';
    sophia_event_privmsg_dehook 'sophia.join';
    delete_sub 'deinit_sophia_join';
}

sub sophia_join {
    my $args = $_[0];
    my ($who, $content) = ($args->[ARG0], $args->[ARG2]);

    my $sophia = ${$args->[HEAP]->{sophia}};
    my @parts = split ' ', $content;
    shift @parts;

    my $chans = sophia_cache_load('sophia_main', 'channels');
    for (@parts) {
        if (length) {
            sophia_log('sophia', sprintf('Joining (%s) requested by %s.', $_, $who));
            # store the channel for listchans
            $chans->{$_} = 1;
            $sophia->yield(join => $_);
        }
    }
}

1;
