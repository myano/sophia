use strict;
use warnings;

sophia_module_add('sophia.modreload', '2.0', \&init_sophia_modreload, \&deinit_sophia_modreload);

sub init_sophia_modreload {
    sophia_command_add('sophia.modreload', \&sophia_modreload, 'Reloads all or a specified module.', '', SOPHIA_ACL_FOUNDER);
    sophia_event_privmsg_hook('sophia.modreload', \&sophia_modreload, 'Reloads all or a specified module.', '', SOPHIA_ACL_FOUNDER);

    return 1;
}

sub deinit_sophia_modreload {
    delete_sub 'init_sophia_modreload';
    delete_sub 'sophia_modreload';
    sophia_command_del 'sophia.mod:reload';
    sophia_event_privmsg_dehook 'sophia.mod:reload';
    delete_sub 'deinit_sophia_modreload';
}

sub sophia_modreload {
    my ($args, $target) = @_;
    my ($who, $where, $content) = ($args->[ARG0], $args->[ARG1], $args->[ARG2]);
    $target //= $where->[0];

    my $sophia = ${$args->[HEAP]->{sophia}};

    my @parts = split ' ', $content;
    shift @parts;

    for (@parts) {
        if ($_ eq '*') {
            sophia_log('sophia', sprintf('Reloading all modules requested by: %s.', $who));
            &sophia_reload_modules;
            $sophia->yield(privmsg => $target => 'All autoloaded modules reloaded.');
        }
        elsif (sophia_reload_module($_)) {
            $sophia->yield(privmsg => $target => sprintf('Module %s reloaded.', $_));
            sophia_log('sophia', sprintf('Module %s reloaded requested by: %s.', $_, $who));
        }
    }
}

1;
