use strict;
use warnings;

sophia_module_add('admin.unquiet', '1.0', \&init_admin_unquiet, \&deinit_admin_unquiet);

sub init_admin_unquiet {
    sophia_command_add('admin.unquiet', \&admin_unquiet, 'Unquiets the user/hostmask.', '');
    sophia_command_add('sophia.unquiet', \&admin_unquiet, 'Unquiets the user/hostmask.', '');

    return 1;
}

sub deinit_admin_unquiet {
    delete_sub 'init_admin_unquiet';
    delete_sub 'admin_unquiet';
    sophia_command_del 'admin.unquiet';
    delete_sub 'deinit_admin_unquiet';
}

sub admin_unquiet {
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

    $sophia::sophia->yield( mode => $where->[0] => sprintf('-%s', 'q' x scalar(@parts)) => $content );
}

1;
