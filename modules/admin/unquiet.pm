use strict;
use warnings;

sophia_module_add('admin.unquiet', '1.0', \&init_admin_unquiet, \&deinit_admin_unquiet);

sub init_admin_unquiet {
    sophia_command_add('admin.unquiet', \&admin_unquiet, 'Unquiets the user/hostmask.', '', SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP);
    sophia_global_command_add('unquiet', \&admin_unquiet, 'Unquiets the user/hostmask.', '', SOPHIA_ACL_OP | SOPHIA_ACL_AUTOOP);

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
    my $args = $_[0];
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);

    my $idx = index $content, ' ';
    return unless $idx > -1;

    $content = substr $content, $idx + 1;
    $content =~ s/^\s+//;
    return unless $content;

    my $sophia = ${$args->[HEAP]->{sophia}};
    my @parts = split / /, $content;

    $sophia->yield( mode => $where->[0] => sprintf('-%s', 'q' x scalar(@parts)) => $content );
}

1;
