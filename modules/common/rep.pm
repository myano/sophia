use strict;
use warnings;

my %reps;

sophia_module_add('common.rep', '1.0', \&init_common_rep, \&deinit_common_rep);

sub init_common_rep {
    sophia_command_add('common.rep', \&common_rep, 'Prints the top 10 users', '');
    sophia_command_add('common.rep++', \&common_rep_add, 'Adds a point to a user.', '');
    sophia_command_add('common.rep--', \&common_rep_rm, 'Removes a point from a user.', '');
    load_rep();

    return 1;
}

sub deinit_common_rep {
    delete_sub 'init_common_rep';
    delete_sub 'common_rep';
    delete_sub 'common_rep_add';
    delete_sub 'common_rep_rm';
    delete_sub 'load_rep';
    sophia_command_del 'common.rep';
    sophia_command_del 'common.rep++';
    sophia_command_del 'common.rep--';
    delete_sub 'deinit_common_rep';
}

sub load_rep {
    open my $fh, '<', 'etc/rep.db' or return;
    undef %reps;
    while (<$fh>)
    {
        my @line = split ' ';
        my $name = $line[0];
        $reps{$name}{UP} = $line[1];
        $reps{$name}{DOWN} = $line[2];
    }
    close $fh;
}

sub save_rep {
    open my $out_fh, '>', 'etc/rep.db' or return;
    for (keys %reps) {
        print {$out_fh} sprintf('%s %d %d%s', $_, $reps{$_}{UP}, $reps{$_}{DOWN}, "\n");
    }
    close $out_fh;
}

sub common_rep_add {
    my $args = $_[0];
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    my $sophia = ${$args->[HEAP]->{sophia}};
    
    my @opts = split ' ', $content;
    return if scalar @opts < 2;

    my $recipient = $opts[1];
    $reps{$recipient}{UP} += 1;
    save_rep();
    $sophia->yield(privmsg => $where->[0] => "One point added to $recipient.");
}

sub common_rep_rm {
    my $args = $_[0];
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    my $sophia = ${$args->[HEAP]->{sophia}};

    my @opts = split ' ', $content;
    return if scalar @opts < 2;

    my $recipient = $opts[1];
    $reps{$recipient}{DOWN} += 1;
    save_rep();
    $sophia->yield(privmsg => $where->[0] => "One point removed from $recipient.");
}

sub common_rep {
    my $args = $_[0];
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    my $sophia = ${$args->[HEAP]->{sophia}};

    my $result =
        join ' | ',
        map { sprintf('%s has +%d/-%d (%d)', $_, $reps{$_}{UP}, $reps{$_}{DOWN}, $reps{$_}{UP} - $reps{$_}{DOWN}); }
        keys %reps;

    my $messages = irc_split_lines($result);
    $sophia->yield(privmsg => $where->[0] => $_) for @{$messages};
}

1;
