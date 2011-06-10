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
        my $name = shift @line;
        $reps{$name} = \@line;
    }
    {close $fh}
}

sub save_rep {
    open my $out_fh, '>', 'etc/rep.db' or return;
    for (keys %reps) {
        print {$out_fh} sprintf('%s %d %d' . "\n", $_, @{$reps{$_}});  
    }
    {close $out_fh}
}    

sub common_rep_add {
    my $args = $_[0];
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    my $sophia = ${$args->[HEAP]->{sophia}};
    $content = substr $content, index($content, ' ') + 1;
    $content =~ s/ //g;
    $content = lc $content;
    $reps{$content}[0] += 1;
    save_rep();
    $sophia->yield(privmsg => $where->[0] => "One point added to $content.");
}

sub common_rep_rm {
    my $args = $_[0];
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    my $sophia = ${$args->[HEAP]->{sophia}};
    $content = substr $content, index($content, ' ') + 1;
    $content =~ s/ //g;
    $content = lc $content;
    $reps{$content}[1] += 1;
    save_rep();
    $sophia->yield(privmsg => $where->[0] => "One point removed from $content.");
}

sub common_rep {
    my $args = $_[0];
    my ($where, $content) = ($args->[ARG1], $args->[ARG2]);
    my $sophia = ${$args->[HEAP]->{sophia}};
    my $saystr = "";
    for (keys %reps)
    {
        my $net = int($reps{$_}[0]) - int($reps{$_}[1]);
        $saystr .= "$_ has +$reps{$_}[0]/-$reps{$_}[1], $net | ";
    }
    $sophia->yield(privmsg => $where->[0] => $saystr);
}

1;
