use strict;
use warnings;
use feature 'switch';

sophia_module_add('config.alias', '1.0', \&init_config_alias, \&deinit_config_alias);

sub init_config_alias {
    sophia_command_add('config.alias', \&config_alias, 'Enables mapping aliases to commands.', '', SOPHIA_ACL_ADMIN);
    sophia_event_privmsg_hook('config.alias', \&config_alias, 'Enables mapping aliases to commands.', '', SOPHIA_ACL_ADMIN);

    return 1;
}

sub deinit_config_alias {
    delete_sub 'init_config_alias';
    delete_sub 'config_alias';
    sophia_command_del 'config.alias';
    sophia_event_privmsg_dehook 'config.alias';
}

sub config_alias {
    my ($args, $target) = @_;
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    $target ||= $where->[0];

    my @opts = split /\s+/, $content;
    my $len = scalar @opts;
    return unless $len > 1;

    my $sophia = ${$args->[HEAP]->{sophia}};
    my $message;
    
    given (lc $opts[1]) {
        when ('del')  {
            $message = sophia_del_alias_option($opts[2]) ?
                        sprintf('alias %s deleted.', lc $opts[2]) :
                        sprintf('alias %s does not exist', lc $opts[2]);
        }
        when ('list') { 
            my $aliases = &sophia_get_aliases;
            $message = join ' ', keys %{$aliases};
        }
        when ('set') {
            $message = sophia_set_alias_option($opts[2], $opts[3]) ?
                        sprintf('alias %s = %s', lc $opts[2], lc $opts[3]) :
                        'Invalid config:alias usage.';
        }
    }

    $sophia->yield(privmsg => $target => $message);
}

1;
