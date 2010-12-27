#!/usr/bin/perl -wT

use strict;
use warnings;
#use lib "$ENV{HOME}/modules";

use POE qw(Component::IRC);

my $nick = "sophia";
my $name = "sophia";
my $passwd = "foo";
my $server = "chat.freenode.net";
my $port = "7070";
my $owner = '';
my $use_ssl = 1;
my $use_ipv6 = 1;

my $irc = POE::Component::IRC->spawn(
	Nick	    => $nick,
	Username	=> $name,
	Password	=> $passwd,
	Ircname	    => $name,
	Server	    => $server,
	Port	    => $port,
	UseSSL	    => $use_ssl,
    #useipv6    => $use_ipv6,
) or die "Failed. $!";

POE::Session->create(
	package_states => [
		main => [ qw(_default _start irc_001 irc_public irc_msg) ],
	],
	heap => { irc => $irc },
);

sub _start {
	my $heap = $_[HEAP];

	my $irc = $heap->{irc};

	$irc->yield( register => "all" );
	$irc->yield( connect => { } );

	return;
}

sub irc_001 {
	my $sender = $_[SENDER];

	my $irc = $sender->get_heap();
    #$irc->yield( privmsg => "Nickserv" => "identify $nick ".$passwd );
	$irc->yield( mode => "$nick +QRiw" );
    $irc->yield( join => '#yano' );
	#$irc->yield( join => $_ ) for @channels;

	return;
}

sub irc_public {
	my ($sender, $who, $where, $content) = @_[SENDER, ARG0 .. ARG2];

	my $nick = ( split /!/, $who )[0];
	my $channel = $where->[0];

	return;
}

sub irc_msg {
	my ($sender, $who, $where, $content) = @_[SENDER, ARG0 .. ARG2];
	my $nick = ( split /!/, $who )[0];
	my $recipient = $where->[0];

	return;
}

sub _default {
	my ($event, $args) = @_[ARG0 .. $#_];
	my @output = ( "$event: " );

	for my $arg (@$args) {
		if ( ref $arg eq 'ARRAY' ) {
			push( @output, '[' . join(', ', @$arg ) . ']' );
		}
		else {
			push ( @output, "'$arg'" );
		}
	}
	print join ' ', @output, "\n";
	return 0;
}

POE::Kernel->run();

