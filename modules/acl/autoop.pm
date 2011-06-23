use strict;
use warnings;

sophia_module_add('acl.autoop', '1.0', \&init_acl_autoop, \&deinit_acl_autoop);

sub init_acl_autoop {
    sophia_event_join_hook('acl.autoop', \&acl_autoop, 'Auto-ops users who joins.', '');

    return 1;
}

sub deinit_acl_autoop {
    delete_sub 'init_acl_autoop';
    delete_sub 'acl_autoop';
    sophia_event_join_dehook 'acl.autoop';
    delete_sub 'deinit_acl_autoop';
}

sub acl_autoop {
    my $args = $_[0];
    my ($who, $chan) = ($args->[ARG0], $args->[ARG1]);

    my $perms = sophia_get_host_perms($who, $chan);
    return if $perms & SOPHIA_ACL_BANNED;
    return unless $perms & SOPHIA_ACL_AUTOOP;

    $who = substr $who, 0, index($who, '!');

    my $sophia = $args->[HEAP]->{sophia};
    $sophia->yield(mode => $chan => '+o' => $who);
}

1;
