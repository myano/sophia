use strict;
use warnings;

sophia_module_add('sophia.restart', '1.0', \&init_sophia_restart, \&deinit_sophia_restart);

sub init_sophia_restart {
    sophia_global_command_add('restart', \&sophia_restart, 'Restarts sophia.', '');
    
    return 1;
}

sub deinit_sophia_restart {
    delete_sub 'init_sophia_restart';
    delete_sub 'sophia_restart';
    sophia_global_command_del 'restart';
    delete_sub 'deinit_sophia_restart';
}

sub sophia_restart {
    my $param = $_[0];
    my @args = @{$param};
    my ($heap, $who) = @args[HEAP, ARG0];
    return unless is_owner($who);

    my $sophia = ${$heap->{sophia}};
    sophia_log('sophia', sprintf('Restarting sophia requested by: %s', $who));
    $sophia::CONFIGURATIONS{DO_RESTART} = 1;
    $sophia->yield(quit => 'Restarting ... ');
}

1;
