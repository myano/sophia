use strict;
use warnings;
use feature 'switch';

sophia_module_add('admin.stopic', '1.0', \&init_admin_stopic, \&deinit_admin_stopic);

sub init_admin_stopic {
    sophia_command_add('admin.stopic', \&admin_stopic, 'Changes the channel topic with a substitute string: s///', '', SOPHIA_ACL_CHANGETOPIC);

    return 1;
}

sub deinit_admin_stopic {
    delete_sub 'init_admin_stopic';
    delete_sub 'admin_stopic';
    sophia_command_del 'admin.stopic';
    delete_sub 'deinit_admin_stopic';
}

sub admin_stopic {
    my ($args, $target) = @_;
    my ($where, $content, $heap) = ($args->[ARG1], $args->[ARG2], $args->[HEAP]);

    my $idx = index $content, ' ';
    return if $idx == -1;
    $content = substr $content, $idx + 1;

    my $target_chan = lc $where->[0];

    # if privmsg, return if @opts is less than 3
    if ($target) {
        $idx = index $content, ' ';
        return if $idx == -1;

        # the first arg is the chan
        $target_chan = lc substr $content, 0, $idx,;

        # the second arg is the reg
        $content = substr $content, $idx + 1;
    }

    $content =~ s/\A\s+//;

    # if no topic is available, do nothing
    return if !defined $heap->{TOPICS}{$target_chan} || $content !~ /\As(.)/;

    my $delimiter = $1;
    my @delim_indeces;
    my @chars = split '', $content;

    my $ignore_next_char = 0;
    CHAR: for my $idx (0 .. $#chars) {
        if ($ignore_next_char) {
            $ignore_next_char = 0;
            next CHAR;
        }

        my $char = $chars[$idx];
        given (lc $char) {
            when ('\\') { $ignore_next_char = 1; }
            when ($delimiter) { push @delim_indeces, $idx; }
        }
    }

    return if scalar @delim_indeces != 3;

    # part 1: s/(..)//
    my $part1 = substr $content, $delim_indeces[0] + 1, $delim_indeces[1] - $delim_indeces[0] - 1;

    # part 2: s//(..)/
    my $part2 = substr $content, $delim_indeces[1] + 1, $delim_indeces[2] - $delim_indeces[1] - 1;

    # part 3: s///(..)
    my $part3 = substr $content, $delim_indeces[2] + 1;

    # if $part3 aren't valid modifiers, then do nothing
    return if $part3 && $part3 !~ /\A[xsmig]+\z/;

    my $topic = $heap->{TOPICS}{$target_chan};
    eval sprintf('$topic =~ s%1$s%2$s%1$s%3$s%1$s%4$s', $delimiter, $part1, $part2, $part3);
    
    my $sophia = ${$heap->{sophia}};
    $sophia->yield( topic => $target_chan => $topic );
}

1;
