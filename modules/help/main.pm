use strict;
use warnings;

sophia_module_add('help.main', '1.0', \&init_help_main, \&deinit_help_main);

sub init_help_main {
    sophia_global_command_add('help', \&help_main, 'Prints the help message for commands.', '');
    sophia_event_privmsg_hook('sophia.help', \&help_main, 'Prints the help message for commands.', '');

    return 1;
}

sub deinit_help_main {
    delete_sub 'init_help_main';
    delete_sub 'help_main';
    sophia_global_command_del 'help';
    sophia_event_privmsg_dehook 'sophia.help';
    delete_sub 'deinit_help_main';
}

sub help_main {
    my ($args, $target) = @_;
    my ($who, $content) = ($args->[ARG0], $args->[ARG2]);

    return unless $content =~ /^.help\s*$/;
    
    my $perms = sophia_get_host_perms($who);
    $target ||= substr $who, 0, index($who, '!');

    my %commands = %{ $sophia::COMMANDS };
    
    my $sophia = ${$args->[HEAP]->{sophia}};
    my @results;

    my $tmp = '';
    for my $module (keys %commands) {
        if (length $tmp >= 300) {
            push @results, $tmp;
            $tmp = '';
        }

        $tmp .= ' ' .
            join ' ',
                # define the output. If the module is sophia, it's a global command. Otherwise, list it as 'module:command'.
                map  { sprintf('%s%s', ($module eq 'sophia' ? '' : $module . ':'), $_); }
                # get the commands that the user has access to
                grep { !$commands{$module}{$_}{access} or $perms & $commands{$module}{$_}{access} }
                # get the commands
                keys %{$commands{$module}};
    }
    push @results, $tmp if $tmp;
    $sophia->yield(notice => $target => $_) for @results;
}

1;