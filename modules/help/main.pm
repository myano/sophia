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
    delete_sub 'help_main_cmd';
    sophia_global_command_del 'help';
    sophia_event_privmsg_dehook 'sophia.help';
    delete_sub 'deinit_help_main';
}

sub help_main {
    my $args = $_[0];
    my ($who, $content) = ($args->[ARG0], $args->[ARG2]);

    return help_main_cmd($args) unless $content =~ /\A.help\s*\z/;
    
    my $perms = sophia_get_host_perms($who);
    $who = substr $who, 0, index($who, '!');

    my %commands = %{ $sophia::COMMANDS };
    
    my $sophia = ${$args->[HEAP]->{sophia}};
    my $cmds = '';

    for my $module (keys %commands) {
        $cmds .= 
            join ' ',
                # define the output. If the module is sophia, it's a global command. Otherwise, list it as 'module:command'.
                map  { sprintf('%s%s', ($module eq 'sophia' ? '' : $module . ':'), $_); }
                # get the commands that the user has access to
                grep { !$commands{$module}{$_}{access} or $perms & $commands{$module}{$_}{access} }
                # get the commands
                keys %{$commands{$module}};
    }
    my $messages = irc_split_lines($cmds);
    $sophia->yield(notice => $who => $_) for @{$messages};
}

sub help_main_cmd {
    my $args = $_[0];
    my ($who, $content) = ($args->[ARG0], $args->[ARG2]);

    my @opts = split ' ', $content;
    return unless $#opts > 0;

    my ($module, $cmd) = (undef, $opts[1]);
    my $perms = sophia_get_host_perms($who);
    $who = substr $who, 0, index($who, '!');

    my $aliases = sophia_get_aliases();
    $cmd = $aliases->{$cmd} if exists $aliases->{$cmd};

    if ($cmd =~ /\A([^:]+):(.+)\z/) {
        ($module, $cmd) = ($1, $2);
    }
    else {
        $module = $sophia::CONFIGURATIONS{GLOBAL_MODULE};
    }

    my $obj = $sophia::COMMANDS->{$module}{$cmd};
    return unless $obj;

    if ($obj->{access}) {
        return unless $perms & $obj->{access};
    }

    my $help = "$sophia::CONFIGURATIONS{BASE_DIR}/help/en/$module/$cmd";
    return unless -e $help;

    my $sophia = ${$args->[HEAP]->{sophia}};
    open my $fh, '<', $help or sophia_log('sophia', "Unable to open help file ($module/$cmd) for reading.") and return;
    $sophia->yield(notice => $who => $_) while <$fh>;
    close $fh;
}

1;
