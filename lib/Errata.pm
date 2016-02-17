package Errata;

use Data::Dumper;
use YAML::XS;

use strict;
use v5.14;

sub load {
    my $class = shift;
    my $file = shift;
    my $s->{e} = _load_errata($file);
    bless $s, $class;
    return $s;
}

sub _load_errata {
    my $file = shift or return undef;

    open my $f, '<:encoding(UTF-8)', $file or die "can't open file : $file";

    my $yml = do { local $/; <$f> };
    my $y = Load($yml);

    my @detail_list = qw(item value alias);

    my $e;
    ref $y eq 'ARRAY' or die "top level not a array";
    my $n = 0;
    for my $h (@{ $y }) {
        $n++;
        ref $h eq 'HASH' or die "second level must be a hash";
        my $uri = $h->{uri} or die "no uri for item : $n";
        ref $h->{errata} eq 'ARRAY' or 
            die "third level must be an array for $uri";
        for my $g (@{ $h->{errata} }) {
            my $i = $g->{item} or die "no item for $uri";
            for my $d (keys %{ $g }) {
                next if $d eq 'item';
                grep $d eq $_, @detail_list or die "invalid detail for $uri";
                $e->{$uri}->{$i}->{$d} = $g->{$d};
            }
        }
    }

    return $e;
}

sub fix_errata {
    my ($s, $r) = @_;
    my $uri = $r->{uri} or return 0;
    my $i = $s->{e}->{$uri} or return 1;
    for (keys %{ $r }) {
        my $d = $i->{$_} or next;
        next unless $d->{alias} eq $r->{$_};
        $r->{$_} = $d->{value};
    }
    return 1;
}

1;
