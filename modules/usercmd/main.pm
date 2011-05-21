use strict;
use warnings;

sophia_module_add('usercmd.main', '1.0', \&init_usercmd_main, \&deinit_usercmd_main);

my $usercmd_db = 'etc/usercmd.db';

sub init_usercmd_main {
    &sophia_usercmd_load;
}

sub deinit_usercmd_main {
    delete_sub 'init_usercmd_main';
    delete_sub 'sophia_usercmd_get';
    delete_sub 'sophia_usercmd_load';
    delete_sub 'deinit_usercmd_main';
}

sub sophia_usercmd_load {
    open my $fh, '<', $usercmd_db or sophia_log('sophia', "Unable to load usercmd.db file: $!") and return 0;

    my ($idx, $cmd, $content);

    LINE: while (<$fh>) {
        chomp;
        next LINE if /^\s*$/;

        $idx = index $_, ' ';
        next LINE if $idx == -1;

        $cmd = substr $_, 0, $idx;
        $content = substr $_, $idx + 1;
        return if $cmd eq '' || $content eq '';

        sophia_cache_store("usercmd/$cmd", $content);
    }

    close $fh;

    return 1;
}

1;
