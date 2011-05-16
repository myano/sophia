use strict;
use warnings;

sophia_module_add('sophia.join', '1.0', \&init_sophia_join, \&deinit_sophia_join);

sub init_sophia_join {
    sophia_global_command_add('join', \&sophia_join, 'Joins one or more channels.', '');
    sophia_event_privmsg_hook('sophia.join', \&sophia_join, 'Joins one or more channels.', '');

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
    my $param = $_[0];
    my @args = @{$param};
    my ($heap, $who, $content) = @args[HEAP, ARG0, ARG2];

    my $perms = sophia_get_host_perms($who);
    return unless $perms & SOPHIA_ACL_FOUNDER;

    my $sophia = ${$heap->{sophia}};
    my @parts = split / /, $content;
    shift @parts;

    for (@parts) {
        if (length) {
            sophia_log('sophia', sprintf('Joining (%s) requested by %s.', $_, $who));
            $sophia->yield(join => $_);
        }
    }
}

1;
