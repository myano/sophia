use strict;
use warnings;

sub sophia_module_load {
    my $module = $_[0];
    $module =~ s/\./\//;
    return -1 unless -e "$Bin/../modules/$module.pm";
    do "$Bin/../modules/$module.pm" and return 1
        or return 0;
}

sub sophia_module_add {
    my ($module_name, $version, $command_hook, $die) = @_;

    # try loading it
    eval {
        # can we hook up the command?
        my $module = &{$command_hook}();
        if ($module) {
            sophia_log('sophia', "[MODULE] $module_name: $module_name v$version successfully loaded.");
            $sophia::MODULES{$module_name}{deconstruct} = $die;
            $sophia::MODULES{$module_name}{version} = $version;
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
    return -1 unless sophia_module_exists($module_name);

    my $die = $sophia::MODULES{$module_name}{deconstruct};
    eval {
        &{$die}();
        delete_sub $die;
        sophia_log('sophia', "[MODULE] $module_name: $module_name v".$sophia::MODULES{$module_name}{version}." successfully unloaded.");
        delete $sophia::MODULES{$module_name};
        return 1;
        1;
    } or sophia_log('sophia', "[MODULE] $module_name: $module_name v".$sophia::MODULES{$module_name}{version}." failed to unload.")
      and return 0;
}

sub sophia_module_exists {
    my $module_name = $_[0];
    return defined $sophia::MODULES{$module_name};
}

sub sophia_command_add {
    my ($module_command, $cmd_hook, $cmd_desc, $cmd_help) = @_;
    my @mod_cmd = split /\./, $module_command;
    $sophia::COMMANDS{$mod_cmd[0]}{$mod_cmd[1]}{init} = $cmd_hook;
    $sophia::COMMANDS{$mod_cmd[0]}{$mod_cmd[1]}{desc} = $cmd_desc;
    $sophia::COMMANDS{$mod_cmd[0]}{$mod_cmd[1]}{help} = $cmd_help;
}

sub sophia_command_del {
    my ($module_name, $cmd_name) = @_;;
    delete $sophia::COMMANDS{$module_name}{$cmd_name};
}

1;
