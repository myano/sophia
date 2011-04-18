use strict;
use warnings;

sophia_module_add('admin.devoice', '1.0', \&init_admin_devoice, \&deinit_admin_devoice);

sub init_admin_devoice {
    sophia_command_add('admin.devoice', \&admin_devoice, 'Devoices the user/hostmask.', '');
    sophia_command_add('sophia.devoice', \&admin_devoice, 'Devoices the user/hostmask.', '');

    return 1;
}

sub deinit_admin_devoice {
    delete_sub 'init_admin_devoice';
    delete_sub 'admin_devoice';
    sophia_command_del 'admin.devoice';
    delete_sub 'deinit_admin_devoice';
}

sub admin_devoice {
    my $param = $_[0];
    my @args = @{$param};
    my ($who, $where, $content) = @args[ARG0 .. ARG2];
    return unless is_admin($who);

    my $idx = index $content, ' ';
    unless ($idx > -1) {
        $content = substr $who, 0, index($who, '!');
        $sophia::sophia->yield( mode => $where->[0] => "-v" => $content );
        return;
    }

    $content = substr $content, $idx + 1;
    $content =~ s/^\s+//;

    unless ($content) {
        $content = substr $who, 0, index($who, '!');
        $sophia::sophia->yield( mode => $where->[0] => "-v" => $content );
    }
    else {
        $sophia::sophia->yield( mode => $where->[0] => "-v" => $content );
    }
}

1;
