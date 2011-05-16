use strict;
use warnings;

sophia_module_add('web.ln_s', '1.0', \&init_web_lns, \&deinit_web_lns);

sub init_web_lns {
    sophia_command_add('web.lns', \&web_lns, 'Creates a ln-s.net redirector link.', '');

    return 1;
}

sub deinit_web_lns {
    delete_sub 'init_web_lns';
    delete_sub 'web_lns';
    sophia_command_del 'web.lns';
    delete_sub 'deinit_web_lns';
}

sub web_lns {
    my $param = $_[0];
    my @args = @{$param};
    my ($where, $content) = @args[ARG1 .. ARG2];

    my $idx = index $content, ' ';
    return unless $idx > -1;

    $content = substr $content, $idx + 1;
    $content =~ s/^\s*//;
    return unless $content =~ /^http:\/\//;

    $idx = index $content, ' ';
    $content = substr($content, 0, $idx) unless $idx == -1;

    my %postdata = (
        url => $content,
    );
    
    my $response = curl_post('http://ln-s.net/home/api.jsp', \%postdata);
    return unless $response;
    
    my @parts = split / /, $response;
    
    return unless $parts[0] eq '200';

    my $sophia = ${$args[HEAP]->{sophia}};
    $sophia->yield(privmsg => $where->[0] => $parts[1]);
}

1;
