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
    return unless is_owner($who);

    my @parts = split / /, $content;
    shift @parts;

    for (@parts) {
        if ($_ eq '*') {
            sophia_log('sophia', sprintf('Reloading all modules requested by: %s.', $who));
            &sophia_reload_modules;
            sophia_write( \$where->[0],
                \sprintf('%s: All autoload modules reloaded.',
                    substr($who, 0, index($who, '!')),
                    $_)
            );
        }
        elsif (sophia_reload_module($_)) {
            sophia_write( \$where->[0],
                \sprintf('%s: Module %s reloaded.',
                    substr($who, 0, index($who, '!')),
                    $_)
            );
            sophia_log('sophia', sprintf('Module %s reloaded requested by: %s.', $_, $who));
        }
    }
}

1;
