use strict;
use warnings;

sub sophia_module_load {
    my $module = $_[0];
    $module =~ s/\./\//;
    return -1 unless -e "$Bin/../modules/$module.pm";
    do "$Bin/../modules/$module.pm" and return 1
        or sophia_log("sophia", $!) and sophia_log("sophia", $@) and return 0;
}

sub sophia_module_add {
    my ($module_name, $version, $command_hook, $die) = @_;

    if (sophia_module_exists($module_name)) {
        sophia_log("sophia", "[MODULE] $module_name already loaded.") and return 0;
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
        sophia_log("sophia", "[MODULE] $module_name is not loaded.") and return -1;
    }

    my $die = $sophia::MODULES->{$module_name}{deconstruct};
    eval {
        &{$die}();
        delete_sub $die;
        sophia_log('sophia', "[MODULE] $module_name: $module_name v".$sophia::MODULES->{$module_name}{version}." successfully unloaded.");
        delete $sophia::MODULES->{$module_name};
        return 1;
        1;
    } or sophia_log('sophia', "[MODULE] $module_name: $module_name v".$sophia::MODULES->{$module_name}{version}." failed to unload.")
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

    $sophia::COMMANDS->{$module}{$command}{init} = $cmd_hook;
    $sophia::COMMANDS->{$module}{$command}{desc} = $cmd_desc;
    $sophia::COMMANDS->{$module}{$command}{help} = $cmd_help;
}

sub sophia_command_del {
    my ($module_command) = @_;
    my $module = substr $module_command, 0, index($module_command, ' ');
    my $command = substr $module_command, index($module_command, ' ') + 1;
    delete $sophia::COMMANDS->{$module}{$command};
}

sub sophia_timer_add {
    my ($name, $control, $init_time) = @_;
    $sophia::TIMERS->{$name}{init} = $control;
    $sophia::TIMERS->{$name}{delay} = $init_time;
}

sub sophia_load_modules {
    my $modconf = $sophia::MODULES_CONFIG;

    open MODULES, "$Bin/../etc/$modconf" or trigger_error('sophia', "Error opening modules config: $!");
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
    return unless sophia_module_exists($module);

    sophia_module_del($module);
    sophia_module_load($module);
}

sub sophia_reload_modules {
    sophia_module_del($_) for keys %{$sophia::MODULES};
    &sophia_load_modules;
}

sub sophia_load_timers {
    my $kernel = ${$_[0]};
    for (keys %{$sophia::TIMERS}) {
        $kernel->state( $_ => \&{$sophia::TIMERS->{$_}{init}} );
        $kernel->alarm( $_ => time() + $sophia::TIMERS->{$_}{delay} );
    }

    delete $sophia::TIMERS->{$_} for keys %{$sophia::TIMERS};
}

1;
