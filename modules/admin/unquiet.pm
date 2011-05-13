use strict;
use warnings;

sophia_module_add('admin.unquiet', '1.0', \&init_admin_unquiet, \&deinit_admin_unquiet);

sub init_admin_unquiet {
    sophia_command_add('admin.unquiet', \&admin_unquiet, 'Unquiets the user/hostmask.', '');
    sophia_global_command_add('unquiet', \&admin_unquiet, 'Unquiets the user/hostmask.', '');

    return 1;
}

sub deinit_admin_unquiet {
    delete_sub 'init_admin_unquiet';
    delete_sub 'admin_unquiet';
    sophia_command_del 'admin.unquiet';
    sophia_global_command_del 'unquiet';
    delete_sub 'deinit_admin_unquiet';
}

sub admin_unquiet {
    my $param = $_[0];
    my @args = @{$param};
    my ($heap, $who, $where, $content) = @args[HEAP, ARG0 .. ARG2];

    my $perms = sophia_get_host_perms($who, $where->[0]);
    return unless $perms & SOPHIA_ACL_ADMIN;

    my $idx = index $content, ' ';
    return unless $idx > -1;

    $content = substr $content, $idx + 1;
    $content =~ s/^\s+//;
    return unless $content;

    my $sophia = ${$heap->{sophia}};
    my @parts = split / /, $content;

    $sophia->yield( mode => $where->[0] => sprintf('-%s', 'q' x scalar(@parts)) => $content );
}

1;
