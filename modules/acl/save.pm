use strict;
use warnings;

sophia_module_add('acl.save', '1.0', \&init_acl_save, \&deinit_acl_save);

sub init_acl_save {
    sophia_command_add('acl.save', \&acl_save, 'Saves the ACL to the DB.', '');

    return 1;
}

sub deinit_acl_save {
    delete_sub 'init_acl_save';
    delete_sub 'acl_save';
    sophia_command_del 'acl.save';
    delete_sub 'deinit_acl_save';
}

sub acl_save {
    my $param = $_[0];
    my @args = @{$param};
    my ($who, $where) = @args[ARG0 .. ARG1];

    my $perms = sophia_get_host_perms($who);
    return unless $perms & SOPHIA_ACL_FOUNDER;

    &sophia_acl_db_save;

    my $sophia = ${$args[HEAP]->{sophia}};

    $sophia->yield(privmsg => $where->[0] => 'ACL saved to DB.');
}
