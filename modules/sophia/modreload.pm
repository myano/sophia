use strict;
use warnings;

sophia_module_add('sophia.modreload', '1.0', \&init_sophia_modreload, \&deinit_sophia_modreload);

sub init_sophia_modreload {
    sophia_global_command_add('mod:reload', \&sophia_modreload, 'Reloads all or a specified module.', '');

    return 1;
}

sub deinit_sophia_modreload {
    delete_sub 'init_sophia_modreload';
    delete_sub 'sophia_modreload';
    sophia_global_command_del 'mod:reload';
    delete_sub 'deinit_sophia_modreload';
}

sub sophia_modreload {
    my $param = $_[0];
    my @args = @{$param};
    my ($who, $where, $content) = @args[ARG0 .. ARG2];

    my $perms = sophia_get_host_perms($who);
    return unless $perms & SOPHIA_ACL_FOUNDER;

    my $sophia = ${$args[HEAP]->{sophia}};

    my @parts = split / /, $content;
    shift @parts;

    for (@parts) {
        if ($_ eq '*') {
            sophia_log('sophia', sprintf('Reloading all modules requested by: %s.', $who));
            &sophia_reload_modules;
            $sophia->yield(privmsg => $where->[0] => 'All autoloaded modules reloaded.');
        }
        elsif (sophia_reload_module($_)) {
            $sophia->yield(privmsg => $where->[0] => sprintf('Module %s reloaded.', $_));
            sophia_log('sophia', sprintf('Module %s reloaded requested by: %s.', $_, $who));
        }
    }
}

1;
