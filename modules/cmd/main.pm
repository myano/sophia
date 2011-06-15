use strict;
use warnings;

my $cmd_db = 'etc/usercmd.db';
my %cmds;

sophia_module_add('cmd.main', '1.0', \&init_cmd_main, \&deinit_cmd_main);

sub init_cmd_main {
    &sophia_cmd_load;

    # store the cmds into sophia's cache
    sophia_cache_store('mod:cmd', 'commands', \%cmds);
}

sub deinit_cmd_main {
    delete_sub 'init_cmd_main';
    delete_sub 'sophia_cmd_load';
    delete_sub 'deinit_cmd_main';
}

sub sophia_cmd_load {
    open my $fh, '<', $cmd_db or sophia_log('sophia', "Unable to load $cmd_db file: $!") and return;

    my ($idx, $cmd, $content);

    LINE: while (<$fh>) {
        chomp;
        next LINE if /\A\s*\z/;

        $idx = index $_, ' ';
        next LINE if $idx == -1;

        $cmd = substr $_, 0, $idx;
        $content = substr $_, $idx + 1;
        return if $cmd eq '' || $content eq '';

        $cmds{$cmd} = $content;
    }

    close $fh;

    return 1;
}

1;
