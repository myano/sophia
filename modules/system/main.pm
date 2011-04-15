use strict;
use warnings;

sophia_module_add("system.main", "1.0", \&init_system, \&deinit_system);

sub init_system {
    sophia_command_add("system.mod:reload", \&system_modreload, "Reloads all or a specified module.", "");
    sophia_command_add("system,mod:load", \&system_modload, "Loads a specified module.", "");
    sophia_command_add("system.mod:unload", \&system_modunload, "Unloads all or a specified module.", "");
    sophia_command_add("system.restart", \&system_restart, "Restarts sophia.", "");
    sophia_command_add("system.shutdown", \&system_shutdown, "Shutdown sophia.", "");

    return 1;
}

sub deinit_system {
    delete_sub "init_system";
    delete_sub "system_modreload";
    delete_sub "system_modload";
    delete_sub "system_modunload";
    delete_sub "system_restart";
    delete_sub "system_shutdown";
    sophia_command_del "system.mod:reload";
    sophia_command_del "system.mod:load";
    sophia_command_del "system.mod:unload";
    sophia_command_del "sophia.restart";
    sophia_command_del "sophia.shutdown";
    delete_sub "deinit_system";
}

sub system_modreload {
    my $param = $_[0];
    my @args = @{$param};
    my ($who, $where, $content) = @args[ARG0 .. ARG2];
    my @parts = split / /, $content;
    shift @parts;

    for (@parts) {
        if (lc eq "all") {
            &sophia_reload_modules;
        }
        else {
            sophia_reload_module($_);
        }
    }
}

sub system_modload {
    my $param = $_[0];
    my @args = @{$param};
    my ($who, $where, $content) = @args[ARG0 .. ARG2];
    my @parts = split / /, $content;
    shift @parts;

    sophia_module_load($_) for @parts;
}

sub system_modunload {
    my $param = $_[0];
    my @args = @{$param};
    my ($who, $where, $content) = @args[ARG0 .. ARG2];
    my @parts = split / /, $content;
    shift @parts;

    sophia_module_del($_) for @parts;
}

sub system_restart {
    my $param = $_[0];
    my @args = @{$param};
    my $who = $args[ARG0];

    sophia_log("sophia", "Restarting sophia by the request of: $who");
    $sophia::sophia->yield(shutdown => "Restarting ...");
    $sophia::sophia->disconnect();
    `$Bin/sophia`;
    exit;
}

sub system_shutdown {
    my $param = $_[0];
    my @args = @{$param};
    my $who = $args[ARG0];

    sophia_log("sophia", "Shutting down sophia by the request of: $who");
    $sophia::sophia->yield(shutdown => "Shutting down ...");
    $sophia::sophia->disconnect();
    exit;
}

1;
