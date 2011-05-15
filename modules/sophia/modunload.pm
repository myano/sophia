use strict;
use warnings;

sophia_module_add('sophia.modunload', '1.0', \&init_sophia_modunload, \&deinit_sophia_modunload);

sub init_sophia_modunload {
    sophia_global_command_add('mod:unload', \&sophia_modunload, 'Unloads all or a specified module.', '');

    return 1;
}

sub deinit_sophia_modunload {
    delete_sub 'init_sophia_modunload';
    delete_sub 'sophia_modunload';
    sophia_global_command_del 'mod:unload';
    delete_sub 'deinit_sophia_modunload';
}

sub sophia_modunload {
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
            sophia_log('sophia', sprintf('Unloading all modules requested by: %s.', $who));
            &sophia_unload_modules;
            $sophia->yield(privmsg => $where->[0] => 'All modules unloaded.');
        }
        elsif (sophia_module_del($_)) {
            $sophia->yield(privmsg => $where->[0] => sprintf('Module %s unloaded.', $_));
            sophia_log('sophia', sprintf('Module %s unloaded requested by: %s.', $_, $who));
        }
    }
}

1;
