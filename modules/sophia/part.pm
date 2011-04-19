use strict;
use warnings;

sophia_module_add('sophia.part', '1.0', \&init_sophia_part, \&deinit_sophia_part);

sub init_sophia_part {
    sophia_global_command_add('part', \&sophia_part, 'Parts one or more channels.', '');

    return 1;
}

sub deinit_sophia_part {
    delete_sub 'init_sophia_part';
    delete_sub 'sophia_part';
    sophia_global_command_del 'part';
    delete_sub 'deinit_sophia_part';
}

sub sophia_part {
    my $param = $_[0];
    my @args = @{$param};
    my ($who, $where, $content) = @args[ARG0 .. ARG2];
    return unless is_owner($who);

    my @parts = split / /, $content;
    shift @parts;

    my $part = 0;
    for (@parts) {
        if (length) {
            sophia_log('sophia', sprintf('Parting (%s) requested by: %s.', $_, $who));
            $sophia::sophia->yield( part => $_ );
            $part = 1;
        }
    }

    unless ($part) {
        sophia_log('sophia', sprintf('Parting (%s) requested by: %s.', $where->[0], $who));
        $sophia::sophia->yield( part => $where->[0] );
    }
}

1;