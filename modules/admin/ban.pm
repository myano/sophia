use strict;
use warnings;

sophia_module_add('admin.ban', '1.0', \&init_admin_ban, \&deinit_admin_ban);

sub init_admin_ban {
    sophia_command_add('admin.ban', \&admin_ban, 'Bans the user/hostmask.', '');
    sophia_global_command_add('ban', \&admin_ban, 'Bans the user/hostmask.', '');

    return 1;
}

sub deinit_admin_ban {
    delete_sub 'init_admin_ban';
    delete_sub 'admin_ban';
    sophia_command_del 'admin.ban';
    delete_sub 'deinit_admin_ban';
}

sub admin_ban {
    my $param = $_[0];
    my @args = @{$param};
    my ($who, $where, $content) = @args[ARG0 .. ARG2];
    return unless is_admin($who);

    my $idx = index $content, ' ';
    return unless $idx > -1;

    $content = substr $content, $idx + 1;
    return unless $content;

    my @parts = split / /, $content;

    $sophia::sophia->yield( mode => $where->[0] => sprintf('+%s', 'b' x scalar(@parts)) => $content );
}

1;
