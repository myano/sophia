use strict;
use warnings;

sophia_module_add('admin.voice', '1.0', \&init_admin_voice, \&deinit_admin_voice);

sub init_admin_voice {
    sophia_command_add('admin.voice', \&admin_voice, 'Voices the user/hostmask.', '', SOPHIA_ACL_VOICE | SOPHIA_ACL_AUTOVOICE);
    sophia_global_command_add('voice', \&admin_voice, 'Voices the user/hostmask.', '', SOPHIA_ACL_VOICE | SOPHIA_ACL_AUTOVOICE);

    return 1;
}

sub deinit_admin_voice {
    delete_sub 'init_admin_voice';
    delete_sub 'admin_voice';
    sophia_command_del 'admin.voice';
    sophia_global_command_del 'voice';
    delete_sub 'deinit_admin_voice';
}

sub admin_voice {
    my $args = $_[0];
    my ($who, $where, $content) = ($args->[ARG0], $args->[ARG1], $args->[ARG2]);

    my $idx = index $content, ' ';
    unless ($idx == -1) {
        $content = substr $content, $idx + 1;
        $content =~ s/^\s+//;
    }

    my $sophia = ${$args->[HEAP]->{sophia}};
    unless ($idx > -1 && $content) {
        $content = substr $who, 0, index($who, '!');
        $sophia->yield( mode => $where->[0] => '+v' => $content );
        return;
    }

    my @parts = split / /, $content;
    $sophia->yield( mode => $where->[0] => sprintf('+%s', 'v' x scalar(@parts)) => $content );
}

1;
