use strict;
use warnings;

sophia_module_add('sophia.version', '1.0', \&init_sophia_version, \&deinit_sophia_version);

sub init_sophia_version {
    sophia_command_add('sophia.version', \&sophia_version, 'Print the current git version.', '');

    return 1;
}

sub deinit_sophia_version {
    delete_sub 'init_sophia_version';
    delete_sub 'sophia_version';
    sophia_command_del 'sophia.version';
    delete_sub 'deinit_sophia_version';
}

sub sophia_version {
    my $args = $_[0];
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);

    my $commit = `git log -1 --pretty=format:'$sophia::CONFIGURATIONS{VERSION} [%H] %cd'`;
    
    my $sophia = ${$args->[HEAP]->{sophia}};
    $sophia->yield(privmsg => $where->[0] => $commit);
}

1;
