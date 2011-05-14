use strict;
use warnings;

sophia_module_add('admin.kick', '1.0', \&init_admin_kick, \&deinit_admin_kick);

sub init_admin_kick {
    sophia_command_add('admin.kick', \&admin_kick, 'Kicks user if bot is a chan op.', '');
    sophia_global_command_add('kick', \&admin_kick, 'Kicks user if bot is a chan op.', '');

    return 1;
}

sub deinit_admin_kick {
    delete_sub 'init_admin_kick';
    delete_sub 'admin_kick';
    sophia_command_del 'admin.kick';
    sophia_global_command_del 'kick';
    delete_sub 'deinit_admin_kick';
}

sub admin_kick {
    my $param = $_[0];
    my @args = @{$param};
    my ($heap, $who, $where, $content) = @args[HEAP, ARG0 .. ARG2];

    my $perms = sophia_get_host_perms($who, $where->[0]);
    return unless $perms & SOPHIA_ACL_ADMIN;
    
    my $idx = index $content, ' ';
    return unless $idx > -1;

    $content = substr $content, $idx + 1;
    $content =~ s/^\s+//;

    $idx = index $content, ' ';
    return unless $idx > -1;

    my $target = substr $content, 0, $idx;
    my $kick_msg = substr $content, $idx + 1;

    my $sophia = ${$heap->{sophia}};
    $sophia->yield( kick => $where->[0] => $target => $kick_msg );
}

1;
