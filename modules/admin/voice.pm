use strict;
use warnings;

sophia_module_add('admin.voice', '1.0', \&init_admin_voice, \&deinit_admin_voice);

sub init_admin_voice {
    sophia_command_add('admin.voice', \&admin_voice, 'Voices the user/hostmask.', '');
    sophia_command_add('sophia.voice', \&admin_voice, 'Voices the user/hostmask.', '');

    return 1;
}

sub deinit_admin_voice {
    delete_sub 'init_admin_voice';
    delete_sub 'admin_voice';
    sophia_command_del 'admin.voice';
    delete_sub 'deinit_admin_voice';
}

sub admin_voice {
    my $param = $_[0];
    my @args = @{$param};
    my ($who, $where, $content) = @args[ARG0 .. ARG2];
    return unless is_admin($who);

    my $idx = index $content, ' ';
    return unless $idx > -1;

    $content = substr $content, $idx + 1;
    $content =~ s/^\s+//;

    unless ($content) {
        $content = substr $who, 0, index($who, '!');
        $sophia::sophia->yield( mode => $where->[0] => "+v" => $content );
    }
    else {
        $sophia::sophia->yield( mode => $where->[0] => "+v" => $content );
    }
}

1;
