use strict;
use warnings;

sophia_module_add('sophia.listchans', '1.0', \&init_sophia_listchans, \&deinit_sophia_listchans);

sub init_sophia_listchans {
    sophia_command_add('sophia.listchans', \&sophia_listchans, 'List channels sophia is told to join.', '', SOPHIA_ACL_FOUNDER);
    sophia_event_privmsg_hook('sophia.listchans', \&sophia_listchans, 'List channels sophia is told to join.', '', SOPHIA_ACL_FOUNDER);

    return 1;
}

sub deinit_sophia_listchans {
    delete_sub 'init_sophia_listchans';
    delete_sub 'sophia_listchans';
    sophia_command_del 'sophia.listchans';
    sophia_event_privmsg_dehook 'sophia.listchans';
    delete_sub 'deinit_sophia_listchans';
}

sub sophia_listchans {
    my ($args, $target) = @_;
    my $who = $args->[ARG0];
    $target //= substr $who, 0, index($who, '!');

    my $chans = sophia_cache_load('sophia_main', 'channels');
    return unless $chans;

    my $result = join ' ', keys %{$chans};
    my $messages = irc_split_lines($result);

    my $sophia = ${$args->[HEAP]->{sophia}};
    $sophia->yield(notice => $target => $_) for @{$messages};
}

1;
