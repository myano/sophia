use strict;
use warnings;

sophia_module_add('acl.load', '1.0', \&init_acl_load, \&deinit_acl_load);

sub init_acl_load {
    sophia_command_add('acl.load', \&acl_load, 'Loads the ACL from the DB.', '', SOPHIA_ACL_FOUNDER);
    sophia_event_privmsg_hook('acl.load', \&acl_load, 'Loads the ACL from the DB.', '', SOPHIA_ACL_FOUNDER);

    return 1;
}

sub deinit_acl_load {
    delete_sub 'init_acl_load';
    delete_sub 'acl_load';
    sophia_command_del 'acl.load';
    sophia_event_privmsg_dehook 'acl.load';
    delete_sub 'deinit_acl_load';
}

sub acl_load {
    my ($args, $target) = @_;
    my $where = $args->[ARG1];
    $target ||= $where->[0];

    my $master = &sophia_get_master;

    &sophia_acl_db_load;

    my $sophia = ${$args->[HEAP]->{sophia}};
    $sophia->yield(privmsg => $target => 'ACL reloaded from DB file.');
}
