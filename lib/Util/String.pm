package Util::String;
use strict;
use warnings;
use Exporter;
use base qw(Exporter);

our @EXPORT_OK = qw(empty ltrim rtrim trim);

sub empty {
    my ($str) = @_;

    # in case it's not a string
    if (!$str) {
        return;
    }

    return $str eq '';
}

sub ltrim {
    my ($str) = @_;
    $str =~ s/^\s+//;
    return $str;
}

sub rtrim {
    my ($str) = @_;
    $str =~ s/\s+$//;
    return $str;
}

sub trim {
    my ($str) = @_;
    $str =~ s/^\s+|\s+$//;
    return $str;
}

1;
