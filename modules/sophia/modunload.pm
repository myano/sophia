use strict;
use warnings;

sophia_module_add('sophia.modunload', '2.0', \&init_sophia_modunload, \&deinit_sophia_modunload);

sub init_sophia_modunload {
    sophia_command_add('sophia.modunload', \&sophia_modunload, 'Unloads all or a specified module.', '', SOPHIA_ACL_FOUNDER);
    sophia_event_privmsg_hook('sophia.modunload', \&sophia_modunload, 'Unloads all or a specified module.', '', SOPHIA_ACL_FOUNDER);

    return 1;
}

sub deinit_sophia_modunload {
    delete_sub 'init_sophia_modunload';
    delete_sub 'sophia_modunload';
    sophia_command_del 'sophia.mod:unload';
    sophia_event_privmsg_dehook 'sophia.mod:unload';
    delete_sub 'deinit_sophia_modunload';
}

sub sophia_modunload {
    my ($args, $target) = @_;
    my ($who, $where, $content) = ($args->[ARG0], $args->[ARG1], $args->[ARG2]);
    $target //= $where->[0];

    my $sophia = ${$args->[HEAP]->{sophia}};

    my @parts = split ' ', $content;
    shift @parts;

    my @loaded;

    for (@parts) {
        if ($_ eq '*') {
            sophia_log('sophia', sprintf('Unloading all modules requested by: %s.', $who));
            &sophia_unload_modules;
            $sophia->yield(privmsg => $target => 'All modules unloaded.');
            return;
        }
        elsif (sophia_module_del($_)) {
            sophia_log('sophia', sprintf('Module %s unloaded requested by: %s.', $_, $who));
            push @loaded, $_;
        }
    }

    my $modules = sprintf('Module%s unloaded: %s.', (scalar @loaded > 1 ? 's' : ''), join(', ', @loaded));
    my $messages = irc_split_lines($modules);

    $sophia->yield(privmsg => $target => $_) for @{$messages};
}

1;
