use strict;
use warnings;

sophia_module_add('sophia.shutdown', '1.0', \&init_sophia_shutdown, \&deinit_sophia_shutdown);

sub init_sophia_shutdown {
    sophia_command_add('sophia.shutdown', \&sophia_shutdown, 'Shutdown sophia.', '');

    return 1;
}

sub deinit_sophia_shutdown {
    delete_sub 'init_sophia_shutdown';
    delete_sub 'sophia_shutdown';
    sophia_command_del 'sophia.shutdown';
    delete_sub 'deinit_sophia_shutdown';
}

sub sophia_shutdown {
    my $param = $_[0];
    my @args = @{$param};
    my $who = $args[ARG0];
    return unless is_owner($who);

    sophia_log('sophia', sprintf('Shutting down sophia requested by: %s.', $who));
    $sophia::sophia->yield(quit => 'Shutting down ... ');
    $sophia::sophia->disconnect();
    exit;
}

1;
