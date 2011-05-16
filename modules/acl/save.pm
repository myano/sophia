use strict;
use warnings;

sophia_module_add('acl.save', '1.0', \&init_acl_save, \&deinit_acl_save);

sub init_acl_save {
    sophia_command_add('acl.save', \&acl_save, 'Saves the ACL to the DB.', '');
    sophia_event_privmsg_hook('acl.save', \&acl_save, 'Saves the ACL to the DB.', '');

    return 1;
}

sub deinit_acl_save {
    delete_sub 'init_acl_save';
    delete_sub 'acl_save';
    sophia_command_del 'acl.save';
    sophia_event_privmsg_dehook 'acl.save';
    delete_sub 'deinit_acl_save';
}

sub acl_save {
    my ($args, $target) = @_;
    my @args = @{$args};
    my ($who, $where) = @args[ARG0 .. ARG1];
    $target ||= $where->[0];

    my $perms = sophia_get_host_perms($who);
    return unless $perms & SOPHIA_ACL_FOUNDER;

    &sophia_acl_db_save;

    my $sophia = ${$args[HEAP]->{sophia}};

    $sophia->yield(privmsg => $target => 'ACL saved to DB.');
}
