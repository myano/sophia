use strict;
use warnings;

sophia_module_add('sophia.version', '1.0', \&init_sophia_version, \&deinit_sophia_version);

sub init_sophia_version {
    sophia_command_add('sophia.version', \&sophia_version, 'Print the current git version.', '');
    sophia_global_command_add('version', \&sophia_version, 'Print the current git version.', '');

    return 1;
}

sub deinit_sophia_version {
    delete_sub 'init_sophia_version';
    delete_sub 'sophia_version';
    sophia_event_public_dehook 'sophia.version';
    delete_sub 'deinit_sophia_version';
}

sub sophia_version {
    my $args = $_[0];
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);

    my $commit_hash = `git log -n 1`;
    my @info = split('\n', $commit_hash);
    @info = @info[0..2];
    
    my $sophia = ${$args->[HEAP]->{sophia}};
    foreach my $val (@info) {
       $sophia->yield(privmsg => $where->[0] => $val);
    }
}

1;
