use strict;
use warnings;

sophia_module_add('sophia.modload', '2.0', \&init_sophia_modload, \&deinit_sophia_modload);

sub init_sophia_modload {
    sophia_command_add('sophia.mod:load', \&sophia_modload, 'Loads a specified module.', '', SOPHIA_ACL_FOUNDER);
    sophia_event_privmsg_hook('sophia.mod:load', \&sophia_modload, 'Loads a specified module.', '', SOPHIA_ACL_FOUNDER);

    return 1;
}

sub deinit_sophia_modload {
    delete_sub 'init_sophia_modload';
    delete_sub 'sophia_modload';
    sophia_command_del 'sophia.mod:load';
    sophia_event_privmsg_dehook 'sophia.mod:load';
    delete_sub 'deinit_sophia_modload';
}

sub sophia_modload {
    my ($args, $target) = @_;
    my ($who, $where, $content) = ($args->[ARG0], $args->[ARG1], $args->[ARG2]);
    $target //= $where->[0];

    my $sophia = ${$args->[HEAP]->{sophia}};

    my @parts = split ' ', $content;
    shift @parts;

    for (@parts) {
        if (sophia_module_load($_)) {
            $sophia->yield(privmsg => $target => sprintf('Module %s loaded.', $_));
            sophia_log('sophia', sprintf('Module %s loaded by: %s.', $_, $who));
        }
    }
}

1;
