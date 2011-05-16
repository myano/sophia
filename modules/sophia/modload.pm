use strict;
use warnings;

sophia_module_add('sophia.modload', '1.0', \&init_sophia_modload, \&deinit_sophia_modload);

sub init_sophia_modload {
    sophia_global_command_add('mod:load', \&sophia_modload, 'Loads a specified module.', '');
    sophia_event_privmsg_hook('sophia.mod:load', \&sophia_modload, 'Loads a specified module.', '');

    return 1;
}

sub deinit_sophia_modload {
    delete_sub 'init_sophia_modload';
    delete_sub 'sophia_modload';
    sophia_global_command_del 'mod:load';
    sophia_event_privmsg_dehook 'sophia.mod:load';
    delete_sub 'deinit_sophia_modload';
}

sub sophia_modload {
    my ($args, $target) = @_;
    my @args = @{$args};
    my ($who, $where, $content) = @args[ARG0 .. ARG2];
    $target ||= $where->[0];

    my $perms = sophia_get_host_perms($who);
    return unless $perms & SOPHIA_ACL_FOUNDER;

    my $sophia = ${$args[HEAP]->{sophia}};

    my @parts = split / /, $content;
    shift @parts;

    for (@parts) {
        if (sophia_module_load($_)) {
            $sophia->yield(privmsg => $target => sprintf('Module %s loaded.', $_));
            sophia_log('sophia', sprintf('Module %s loaded by: %s.', $_, $who));
        }
    }
}

1;
