use strict;
use warnings;

sophia_module_add('sophia.restart', '2.0', \&init_sophia_restart, \&deinit_sophia_restart);

sub init_sophia_restart {
    sophia_command_add('sophia.restart', \&sophia_restart, 'Restarts sophia.', '', SOPHIA_ACL_FOUNDER);
    sophia_event_privmsg_hook('sophia.restart', \&sophia_restart, 'Restarts sophia.', '', SOPHIA_ACL_FOUNDER);
    
    return 1;
}

sub deinit_sophia_restart {
    delete_sub 'init_sophia_restart';
    delete_sub 'sophia_restart';
    sophia_command_del 'sophia.restart';
    sophia_event_privmsg_dehook 'sophia.restart';
    delete_sub 'deinit_sophia_restart';
}

sub sophia_restart {
    my $args = $_[0];
    my $who = $args->[ARG0];
    my $sophia = ${$args->[HEAP]->{sophia}};

    sophia_log('sophia', sprintf('Restarting sophia requested by: %s', $who));
    $sophia::CONFIGURATIONS{DO_RESTART} = 1;
    $sophia->yield(quit => 'Restarting ... ');
}

1;
