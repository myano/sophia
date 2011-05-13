use strict;
use warnings;

sophia_module_add('sophia.modload', '1.0', \&init_sophia_modload, \&deinit_sophia_modload);

sub init_sophia_modload {
    sophia_global_command_add('mod:load', \&sophia_modload, 'Loads a specified module.', '');

    return 1;
}

sub deinit_sophia_modload {
    delete_sub 'init_sophia_modload';
    delete_sub 'sophia_modload';
    sophia_global_command_del 'mod:load';
    delete_sub 'deinit_sophia_modload';
}

sub sophia_modload {
    my $param = $_[0];
    my @args = @{$param};
    my ($who, $where, $content) = @args[ARG0 .. ARG2];

    my $perms = sophia_get_host_perms($who);
    return unless $perms & SOPHIA_ACL_FOUNDER;

    my @parts = split / /, $content;
    shift @parts;

    for (@parts) {
        if (sophia_module_load($_)) {
            sophia_write( \$where->[0],
                \sprintf('%s: Module %s loaded.',
                    substr($who, 0, index($who, '!')),
                    $_)
            );
            sophia_log('sophia', sprintf('Module %s loaded by: %s.', $_, $who));
        }
    }
}

1;
