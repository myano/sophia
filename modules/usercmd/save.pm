use strict;
use warnings;

sophia_module_add('usercmd.save', '1.0', \&init_usercmd_save, \&deinit_usercmd_save);

my $usercmd_db = 'etc/usercmd.db';

sub init_usercmd_save {
    sophia_command_add('cmd.save', \&usercmd_save, 'Saves the user-defined commands.', '', SOPHIA_ACL_FRIEND);

    return 1;
}

sub deinit_usercmd_save {
    delete_sub 'init_usercmd_save';
    delete_sub 'usercmd_save';
    sophia_command_del 'cmd.save';
    delete_sub 'deinit_usercmd_save';
}

sub usercmd_save {
    my $args = $_[0];
    my $where = $args->[ARG1];
    my $usercmds = &sophia_cache_load('usercmd');

    open my $fh, '>', $usercmd_db or sophia_log('sophia', "Unable to open usercmd.db file for saving: $!") and return 0;
    print $fh $_, ' ', $usercmds->{$_} for keys %{$usercmds};
    close $fh;

    my $sophia = ${$_[0]->[HEAP]->{sophia}};
    $sophia->yield(privmsg => $where->[0] => 'User-defined commands saved to DB.');
}

1;
