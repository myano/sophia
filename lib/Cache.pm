use strict;
use warnings;

my %CACHE;

sub sophia_cache_store {
    my ($namespace, $key, $val) = @_;
    return unless $namespace && $key && $val;

    $key = lc $key;
    $CACHE{$namespace}{$key} = $val;

    return 1;
}

sub sophia_cache_load {
    my ($namespace, $key) = @_;
    return unless $namespace;

    $key //= '';

    ($namespace, $key) = trim($namespace, $key);
    ($namespace, $key) = (lc $namespace, lc $key);

    return $CACHE{$namespace} if !$key;

    return $CACHE{$namespace}{$key};
}

sub sophia_cache_del {
    my ($namespace, $key) = @_;
    return unless $namespace;

    $key //= '';

    ($namespace, $key) = trim($namespace, $key);
    ($namespace, $key) = (lc $namespace, lc $key);

    delete $CACHE{$namespace}{$key} and return if $key;
    delete $CACHE{$namespace} if $namespace;
}

sub sophia_cache_key_exists {
    my ($namespace, $key) = @_;
    return unless $namespace;

    $key //= '';

    ($namespace, $key) = trim($namespace, $key);
    ($namespace, $key) = (lc $namespace, lc $key);

    return exists $CACHE{$namespace} if !$key;

    return exists $CACHE{$namespace}{$key};
}

1;
