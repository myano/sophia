use strict;
use warnings;

sophia_module_add('sophia.modunload', '1.0', \&init_sophia_modunload, \&deinit_sophia_modunload);

sub init_sophia_modunload {
    sophia_command_add('sophia.mod:unload', \&sophia_modunload, 'Unloads all or a specified module.', '');

    return 1;
}

sub deinit_sophia_modunload {
    delete_sub 'init_sophia_modunload';
    delete_sub 'sophia_modunload';
    sophia_command_del 'sophia.mod:unload';
    delete_sub 'deinit_sophia_modunload';
}

sub sophia_modunload {
    my $param = $_[0];
    my @args = @{$param};
    my ($who, $where, $content) = @args[ARG0 .. ARG2];
    return unless is_owner($who);

    my @parts = split / /, $content;
    shift @parts;

    for (@parts) {
        if ($_ eq '*') {
            sophia_log('sophia', sprintf('Unloading all modules requested by: %s.', $who));
            &sophia_unload_modules;
            sophia_write( \$where->[0],
                \sprintf('%s: All modules unloaded.',
                    substr($who, 0, index($who, '!')),
                    $_)
            );
        }
        elsif (sophia_module_del($_)) {
            sophia_write( \$where->[0],
                \sprintf('%s: Module %s unloaded.',
                    substr($who, 0, index($who, '!')),
                    $_)
            );
            sophia_log('sophia', sprintf('Module %s unloaded requested by: %s.', $_, $who));
        }
    }
}

1;
