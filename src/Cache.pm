use strict;
use warnings;

my %CACHE;

sub sophia_cache_store {
    my ($key, $val) = @_;
    return 0 unless $key && $val;

    ($key, $val) = trim($key, $val);
    ($key, $val) = (lc $key, lc $val);

    my $idx = index $key, '/';
    return 0 unless $idx > 0;

    my $namespace = substr $key, 0, $idx;
    $key = substr $key, $idx + 1;

    $CACHE{$namespace}{$key} = $val;

    return 1;
}

sub sophia_cache_load {
    my ($namespace, $key) = @_;
    return unless $namespace;

    $key ||= '';

    ($namespace, $key) = trim($namespace, $key);
    ($namespace, $key) = (lc $namespace, lc $key);

    return $CACHE{$namespace} if !$key;

    return $CACHE{$namespace}{$key};
}

sub sophia_cache_key_exists {
    my ($namespace, $key) = @_;
    return 0 unless $namespace;

    $key ||= '';

    ($namespace, $key) = trim($namespace, $key);
    ($namespace, $key) = (lc $namespace, lc $key);

    return exists $CACHE{$namespace} if !$key;

    return exists $CACHE{$namespace}{$key};
}

1;
