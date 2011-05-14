use strict;
use warnings;

sophia_module_add('acl.load', '1.0', \&init_acl_load, \&deinit_acl_load);

sub init_acl_load {
    sophia_command_add('acl.load', \&acl_load, 'Loads the ACL from the DB.', '');

    return 1;
}

sub deinit_acl_load {
    delete_sub 'init_acl_load';
    delete_sub 'acl_load';
    sophia_command_del 'acl.load';
    delete_sub 'deinit_acl_load';
}

sub acl_load {
    my $param = $_[0];
    my @args = @{$param};
    my ($who, $where) = @args[ARG0 .. ARG1];

    my $perms = sophia_get_host_perms($who);
    return unless $perms & SOPHIA_ACL_FOUNDER;

    my $master = &sophia_get_master;

    &sophia_acl_db_load;

    my $sophia = ${$args[HEAP]->{sophia}};
    $sophia->yield(privmsg => $where->[0] => 'ACL reloaded from DB file.');
}
