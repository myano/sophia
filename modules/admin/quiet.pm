use strict;
use warnings;

sophia_module_add('admin.quiet', '1.0', \&init_admin_quiet, \&deinit_admin_quiet);

sub init_admin_quiet {
    sophia_command_add('admin.quiet', \&admin_quiet, 'Quiets the user/hostmask.', '');
    sophia_global_command_add('quiet', \&admin_quiet, 'Quiets the user/hostmask.', '');

    return 1;
}

sub deinit_admin_quiet {
    delete_sub 'init_admin_quiet';
    delete_sub 'admin_quiet';
    sophia_command_del 'admin.quiet';
    delete_sub 'deinit_admin_quiet';
}

sub admin_quiet {
    my $param = $_[0];
    my @args = @{$param};
    my ($who, $where, $content) = @args[ARG0 .. ARG2];
    return unless is_admin($who);

    my $idx = index $content, ' ';
    return unless $idx > -1;

    $content = substr $content, $idx + 1;
    $content =~ s/^\s+//;
    return unless $content;

    my @parts = split / /, $content;

    $sophia::sophia->yield( mode => $where->[0] => sprintf('+%s', 'q' x scalar(@parts)) => $content );
}

1;
