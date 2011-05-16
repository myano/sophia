use strict;
use warnings;

sophia_module_add('config.set', '1.0', \&init_config_set, \&deinit_config_set);

sub init_config_set {
    sophia_command_add('config.set', \&config_set, 'Sets a sophia conf option.', '');
    sophia_event_privmsg_hook('config.set', \&config_set, 'Sets a sophia conf option.', '');

    return 1;
}

sub deinit_config_set {
    delete_sub 'init_config_set';
    delete_sub 'config_set';
    sophia_command_del 'config.set';
    sophia_event_privmsg_dehook 'config.set';
    delete_sub 'deinit_config_set';
}

sub config_set {
    my ($args, $target) = @_;
    my @args = @{$args};
    my ($who, $where, $content) = @args[ARG0 .. ARG2];
    $target ||= $where->[0];

    my $perms = sophia_get_host_perms($who);
    return unless $perms & SOPHIA_ACL_FOUNDER;

    my @opts = split /\s+/, $content;

    my $sophia = ${$args[HEAP]->{sophia}};

    my $message = sophia_set_config_option(\@opts) ?
                    sprintf('%s = %s', $opts[1], $opts[2]) :
                    sprintf('Invalid option %1$s%2$s%1$s.', "\x02", $opts[1]);

    $sophia->yield(privmsg => $target => $message);
}

1;
