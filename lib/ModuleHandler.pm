use strict;
use warnings;

sub sophia_module_load {
    my $module = $_[0];

    # if the module exists, don't re-load
    if (exists $sophia::MODULES->{$_[0]}) {
        sophia_log('sophia', "[MODULE] modules/$module.pm is already loaded.");
        return;
    }

    $module =~ s/\./\//;
    return unless -e "$Bin/../modules/$module.pm";

    unless (my $fd = do "$Bin/../modules/$module.pm") {
        sophia_log('sophia', "[MODULE] modules/$module.pm cannot be read: $!") unless defined $fd || $!;
        sophia_log('sophia', "[MODULE] modules/$module.pm failed to compile: $@") if $@;
        sophia_log('sophia', "[MODULE] modules/$module.pm read and compiled but failed to run") unless $fd;
        return;
    }
    return 1;
}

sub sophia_module_add {
    my ($module_name, $version, $command_hook, $die) = @_;

    if (sophia_module_exists($module_name)) {
        sophia_log('sophia', sprintf('[MODULE] %s is already loaded.', $module_name)) and return;
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
        return;
    }
    # something went wrong
    or sophia_log('sophia', "[MODULE] $module_name: $module_name v$version failed to load.")
    and return;
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
      and return;
}

sub sophia_module_exists {
    my $module_name = $_[0];
    return defined $sophia::MODULES->{$module_name};
}

sub sophia_command_add {
    my ($module_command, $cmd_hook, $cmd_desc, $cmd_help, $cmd_access) = @_;
    my ($module, $command);
    $module = substr $module_command, 0, index($module_command, '.');
    $command = substr $module_command, index($module_command, '.') + 1;

    $cmd_access //= SOPHIA_ACL_NONE;
    $sophia::COMMANDS->{$module}{$command}{init} = $cmd_hook;
    $sophia::COMMANDS->{$module}{$command}{desc} = $cmd_desc;
    $sophia::COMMANDS->{$module}{$command}{help} = $cmd_help;
    $sophia::COMMANDS->{$module}{$command}{access} = $cmd_access;
}

sub sophia_command_del {
    my ($module_command) = @_;
    return unless $module_command;

    my $module = substr $module_command, 0, index($module_command, '.');
    my $command = substr $module_command, index($module_command, '.') + 1;
    return unless $module && $command;

    delete $sophia::COMMANDS->{$module}{$command};
}

sub sophia_timer_add {
    my ($name, $control, $init_time) = @_;
    $sophia::TIMERS->{$name}{init} = $control;
    $sophia::TIMERS->{$name}{delay} = $init_time;
}

sub sophia_load_modules {
    return unless -e $sophia::CONFIGURATIONS{MODULES_CONFIG};

    open my $fh, '<', $sophia::CONFIGURATIONS{MODULES_CONFIG}
        or sophia_log('sophia', "Error opening modules config: $!");

    LINE: while (<$fh>) {
        chomp;
        s/\A\s+//;
        next LINE if !/\Aloadmodule / or !/\;/;  # ignoring comments and lame lines
        s/\;//;
        s/\Aloadmodule\s+//;
        s/"//g;

        sophia_module_load($_);
    }
    close $fh;
}

sub sophia_reload_module {
    my $module = shift;
    unless (sophia_module_exists($module)) {
        sophia_log('sophia', sprintf('Module %s is not loaded.', $module));
        return;
    }

    unless (sophia_module_del($module)) {
        sophia_log('sophia', sprintf('Module %s failed to unload.', $module));
        return;
    }

    unless (sophia_module_load($module)) {
        sophia_log('sophia', sprintf('Module %s failed to load.', $module));
        return;
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
