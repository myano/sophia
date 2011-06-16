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

    my @loaded;

    for (@parts) {
        if ($_ eq '*') {
            sophia_log('sophia', sprintf('Reloading all modules requested by: %s.', $who));
            &sophia_reload_modules;
            $sophia->yield(privmsg => $target => 'All autoloaded modules reloaded.');
        }
        elsif (sophia_reload_module($_)) {
            sophia_log('sophia', sprintf('Module %s reloaded requested by: %s.', $_, $who));
            push @loaded, $_;
        }
    }

    my $len = scalar @loaded;

    # if no modules are loaded, then tell the user
    if ($len == 0) {
        $sophia->yield(privmsg => $target => 'All modules failed to reload.');
        return;
    }

    my $modules = sprintf('Module%s reloaded: %s.', ($len > 1 ? 's' : ''), join(', ', @loaded));
    my $messages = irc_split_lines($modules);

    $sophia->yield(privmsg => $target => $_) for @{$messages};
}

1;
