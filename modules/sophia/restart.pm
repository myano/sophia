use strict;
use warnings;

sophia_module_add('sophia.restart', '1.0', \&init_sophia_restart, \&deinit_sophia_restart);

sub init_sophia_restart {
    sophia_global_command_add('restart', \&sophia_restart, 'Restarts sophia.', '');
    sophia_event_privmsg_hook('sophia.restart', \&sophia_restart, 'Restarts sophia.', '');
    
    return 1;
}

sub deinit_sophia_restart {
    delete_sub 'init_sophia_restart';
    delete_sub 'sophia_restart';
    sophia_global_command_del 'restart';
    sophia_event_privmsg_dehook 'sophia.restart';
    delete_sub 'deinit_sophia_restart';
}

sub sophia_restart {
    my $param = $_[0];
    my @args = @{$param};
    my ($heap, $who) = @args[HEAP, ARG0];

    my $perms = sophia_get_host_perms($who);
    return unless $perms & SOPHIA_ACL_FOUNDER;

    my $sophia = ${$heap->{sophia}};
    sophia_log('sophia', sprintf('Restarting sophia requested by: %s', $who));
    $sophia::CONFIGURATIONS{DO_RESTART} = 1;
    $sophia->yield(quit => 'Restarting ... ');
}

1;
