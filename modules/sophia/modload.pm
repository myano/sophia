use strict;
use warnings;

sophia_module_add('sophia.modload', '2.0', \&init_sophia_modload, \&deinit_sophia_modload);

sub init_sophia_modload {
    sophia_command_add('sophia.modload', \&sophia_modload, 'Loads a specified module.', '', SOPHIA_ACL_MASTER);
    sophia_event_privmsg_hook('sophia.modload', \&sophia_modload, 'Loads a specified module.', '', SOPHIA_ACL_MASTER);

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

    my $sophia = $args->[HEAP]->{sophia};

    my @parts = split ' ', $content;
    shift @parts;

    my @loaded;

    for (@parts) {
        if (sophia_module_load($_)) {
            slog('sophia', sprintf('Module %s loaded by: %s.', $_, $who));
            push @loaded, $_;
        }
    }

    my $len = scalar @loaded;

    # if no modules are loaded, then tell the user
    if ($len == 0) {
        $sophia->yield(privmsg => $target => 'All modules failed to load.');
        return;
    }

    my $modules = sprintf('Module%s loaded: %s.', (scalar @loaded > 1 ? 's' : ''), join(', ', @loaded));
    my $messages = irc_split_lines($modules);

    $sophia->yield(privmsg => $target => $_) for @{$messages};
}

1;
