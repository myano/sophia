use strict;
use warnings;

my $global_module = $sophia::CONFIGURATIONS{GLOBAL_MODULE};
sub sophia_module_load {
    my $module = $_[0];
    $module =~ s/\./\//;
    return 0 unless -e "$Bin/../modules/$module.pm";

    unless (my $fd = do "$Bin/../modules/$module.pm") {
        sophia_log('sophia', "[MODULE] modules/$module.pm cannot be read: $!") unless defined $fd || $!;
        sophia_log('sophia', "[MODULE] modules/$module.pm failed to compile: $@") if $@;
        sophia_log('sophia', "[MODULE] modules/$module.pm read and compiled but failed to run") unless $fd;
        return 0;
    }
    return 1;
}

sub sophia_module_add {
    my ($module_name, $version, $command_hook, $die) = @_;

    if (sophia_module_exists($module_name)) {
        sophia_log('sophia', sprintf('[MODULE] %s is already loaded.', $module_name)) and return 0;
    }

    # try loading it
    eval {
        # can we hook up the command?
        my $module = &{$command_hook}();
        if ($module) {
            sophia_log('sophia', "[MODULE] $module_name: $module_name v$version successfully loaded.");
            $sophia::MODULES->{$module_name}{deconstruct} = $die;
            $sophia::MODULES->{$module_name}{version} = $version;
            return 1;
            1;
        }
        
        &{$die}();
        sophia_log('sophia', "[MODULE] $module_name: $module_name v$version failed to load.");
        return 0;
    }
    # something went wrong
    or sophia_log('sophia', "[MODULE] $module_name: $module_name v$version failed to load.")
    and return 0;
}

sub sophia_module_del {
    my $module_name = $_[0];

    unless (sophia_module_exists($module_name)) {
        sophia_log('sophia', "[MODULE] $module_name is not loaded.") and return -1;
    }

    my $die = $sophia::MODULES->{$module_name}{deconstruct};
    eval {
        &{$die}();
        delete_sub $die;
        sophia_log('sophia', "[MODULE] $module_name: $module_name v".$sophia::MODULES->{$module_name}{version}." successfully unloaded.");
        delete $sophia::MODULES->{$module_name};
        return 1;
        1;
    } or sophia_log('sophia', "[MODULE] $module_name: $module_name v".$sophia::MODULES->{$module_name}{version}.' failed to unload.')
      and return 0;
}

sub sophia_module_exists {
    my $module_name = $_[0];
    return defined $sophia::MODULES->{$module_name};
}

sub sophia_command_add {
    my ($module_command, $cmd_hook, $cmd_desc, $cmd_help) = @_;
    my ($module, $command);
    $module = substr $module_command, 0, index($module_command, '.');
    $command = substr $module_command, index($module_command, '.') + 1;
    return if $module eq $global_module;

    $sophia::COMMANDS->{$module}{$command}{init} = $cmd_hook;
    $sophia::COMMANDS->{$module}{$command}{desc} = $cmd_desc;
    $sophia::COMMANDS->{$module}{$command}{help} = $cmd_help;
}

sub sophia_global_command_add {
    my ($command, $cmd_hook, $cmd_desc, $cmd_help) = @_;
    $sophia::COMMANDS->{$global_module}{$command}{init} = $cmd_hook;
    $sophia::COMMANDS->{$global_module}{$command}{desc} = $cmd_desc;
    $sophia::COMMANDS->{$global_module}{$command}{help} = $cmd_help;
}

sub sophia_event_join_hook {
    sophia_event_hook($sophia::EVENTSCONF{join}, \@_); 
}

sub sophia_event_kick_hook {
    sophia_event_hook($sophia::EVENTSCONF{kick}, \@_);
}

sub sophia_event_nick_hook {
    sophia_event_hook($sophia::EVENTSCONF{nick}, \@_);
}

sub sophia_event_notice_hook {
    sophia_event_hook($sophia::EVENTSCONF{notice}, \@_);
}

sub sophia_event_part_hook {
    sophia_event_hook($sophia::EVENTSCONF{part}, \@_);
}

sub sophia_event_privmsg_hook {
    sophia_event_hook($sophia::EVENTSCONF{privmsg}, \@_);
}

sub sophia_event_public_hook {
    sophia_event_hook($sophia::EVENTSCONF{public}, \@_);
}

sub sophia_event_quit_hook {
    sophia_event_hook($sophia::EVENTSCONF{quit}, \@_);
}

sub sophia_event_hook {
    my ($event, $vals) = @_;
    my ($mod_cmd, $cmd_hook, $cmd_desc, $cmd_help) = @{$vals};
    return unless $event;

    $sophia::EVENTS->{$event}{$mod_cmd}{init} = $cmd_hook;
    $sophia::EVENTS->{$event}{$mod_cmd}{desc} = $cmd_desc;
    $sophia::EVENTS->{$event}{$mod_cmd}{help} = $cmd_help;
}

sub sophia_command_del {
    my ($module_command) = @_;
    return unless $module_command;

    my $module = substr $module_command, 0, index($module_command, '.');
    my $command = substr $module_command, index($module_command, '.') + 1;
    return unless $module && $command && $module ne $global_module;

    delete $sophia::COMMANDS->{$module}{$command};
}

sub sophia_global_command_del {
    my $command = $_[0];
    return unless $command;

    delete $sophia::COMMANDS->{$global_module}{$command};
}

sub sophia_event_join_dehook {
    sophia_event_dehook($sophia::EVENTSCONF{join}, $_[0]); 
}

sub sophia_event_kick_dehook {
    sophia_event_dehook($sophia::EVENTSCONF{kick}, $_[0]);
}

sub sophia_event_nick_dehook {
    sophia_event_dehook($sophia::EVENTSCONF{nick}, $_[0]);
}

sub sophia_event_notice_dehook {
    sophia_event_dehook($sophia::EVENTSCONF{notice}, $_[0]);
}

sub sophia_event_part_dehook {
    sophia_event_dehook($sophia::EVENTSCONF{part}, $_[0]);
}

sub sophia_event_privmsg_dehook {
    sophia_event_dehook($sophia::EVENTSCONF{privmsg}, $_[0]);
}

sub sophia_event_public_dehook {
    sophia_event_dehook($sophia::EVENTSCONF{public}, $_[0]);
}

sub sophia_event_quit_dehook {
    sophia_event_dehook($sophia::EVENTSCONF{quit}, $_[0]);
}

sub sophia_event_dehook {
    my ($event, $mod_cmd) = @_;
    return unless $event && $mod_cmd;

    delete $sophia::EVENTS->{$event}{$mod_cmd};
}

sub sophia_timer_add {
    my ($name, $control, $init_time) = @_;
    $sophia::TIMERS->{$name}{init} = $control;
    $sophia::TIMERS->{$name}{delay} = $init_time;
}

sub sophia_load_modules {
    return unless -e $sophia::CONFIGURATIONS{MODULES_CONFIG};

    open MODULES, $sophia::CONFIGURATIONS{MODULES_CONFIG}
        or sophia_log('sophia', "Error opening modules config: $!");

    LINE: while (<MODULES>) {
        chomp;
        s/^\s+//;
        next LINE if !/^loadmodule / or !/\;/;  # ignoring comments and lame lines
        s/\;//;
        s/^loadmodule\s+//;
        s/"//g;

        sophia_module_load($_);
    }
    close MODULES;
}

sub sophia_reload_module {
    my $module = shift;
    unless (sophia_module_exists($module)) {
        sophia_log('sophia', sprintf('Module %s is not loaded.', $module));
        return 0;
    }

    unless (sophia_module_del($module)) {
        sophia_log('sophia', sprintf('Module %s failed to unload.', $module));
        return 0;
    }

    unless (sophia_module_load($module)) {
        sophia_log('sophia', sprintf('Module %s failed to load.', $module));
        return 0;
    }
    return 1;
}

sub sophia_unload_modules {
    sophia_module_del($_) for keys %{$sophia::MODULES};
}

sub sophia_reload_modules {
    &sophia_unload_modules;
    &sophia_load_modules;
}

sub sophia_load_timers {
    my $kernel = ${$_[0]};
    for (keys %{$sophia::TIMERS}) {
        $kernel->state( $_ => $sophia::TIMERS->{$_}{init} );
        $kernel->alarm( $_ => time() + $sophia::TIMERS->{$_}{delay} );
    }

    delete $sophia::TIMERS->{$_} for keys %{$sophia::TIMERS};
}

1;
