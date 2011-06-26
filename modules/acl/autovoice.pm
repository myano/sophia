use strict;
use warnings;

sophia_module_add('acl.autovoice', '1.0', \&init_acl_autovoice, \&deinit_acl_autovoice);

sub init_acl_autovoice {
    sophia_event_join_hook('acl.autovoice', \&acl_autovoice, 'Auto-voices users who joins.', '');

    return 1;
}

sub deinit_acl_autovoice {
    delete_sub 'init_acl_autovoice';
    delete_sub 'acl_autovoice';
    sophia_event_join_dehook 'acl.autovoice';
    delete_sub 'deinit_acl_autovoice';
}

sub acl_autovoice {
    my $args = $_[0];
    my ($who, $chan) = ($args->[ARG0], $args->[ARG1]);

    my $perms = sophia_get_host_perms($who, $chan);
    return if $perms & SOPHIA_ACL_BANNED;
    return unless $perms & SOPHIA_ACL_AUTOVOICE;

    $who = substr $who, 0, index($who, '!');

    my $sophia = $args->[HEAP]->{sophia};
    $sophia->yield(mode => $chan => '+v' => $who);
}

1;
