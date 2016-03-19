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

sub _load_array {
    my $h = shift or return undef;

    my $x;
    for my $g (@{ $h }) {
        my $i = $g->{item};
        if (!$i) {
            for (keys %{ $g }) {
                ref $g->{$_} eq 'ARRAY' or return undef;
                $x->{$_} = _load_array($g->{$_}) or return undef;
            }
            next;
        }
        for my $d (keys %{ $g }) {
            next if $d eq 'item';
            grep $d eq $_, qw(value alias) or return undef;
            $x->{$i}->{$d} = $g->{$d};
        }
    }

    return $x;
}

sub _merge_errata {
    my ($e, $a) = @_;
    return 1 if !$a;
    for my $k (keys %{ $a }) {
        if (!$e->{$k}) {
            $e->{$k} = $a->{$k};
            next;
        }
        if (grep 'value' eq $_, keys %{ $a->{$k} }) {
            $e->{$k} = $a->{$k};
            next;
        }
        _merge_errata($e->{$k}, $a->{$k});
    }
    return 1;
}

sub _load_errata {
    my $file = shift or return undef;

    open my $f, '<:encoding(UTF-8)', $file or die "can't open file : $file";
    my $yml = do { local $/; <$f> };
    my $y = Load($yml);
    close $f;

    my $e;
    ref $y eq 'ARRAY' or die "top level not a array";
    my $n = 0;
    for my $h (@{ $y }) {
        $n++;
        ref $h eq 'HASH' or die "second level must be a hash";
        my $uri = $h->{uri} or die "no uri for item : $n";
        ref $h->{errata} eq 'ARRAY' or 
            die "third level must be an array for $uri";
        my $a = _load_array($h->{errata}) or die "invalid array values for $uri";
        _merge_errata(\%{ $e->{$uri} }, $a);
    }

    return $e;
}

sub _fix_items {
    my ($e, $r) = @_;
    for (keys %{ $r }) {
        my $d = $e->{$_} or next;
        my $do_next_level = 0;
        for my $k (keys %{ $d }) {
            next if grep $k eq $_, qw(alias value);
            $do_next_level = 1;
        }
        if ($do_next_level) {
            _fix_items($d, $r->{$_});
            next;
        }

        my $kv = 0;
        for my $k (qw(alias value)) {
            $kv++ if grep $_ eq $k, keys %{ $d };
        }
        next unless $kv == 2;
        next unless $d->{alias} eq $r->{$_};
        next if $d->{value} eq '_DIFF_OKAY_';
        $r->{$_} = $d->{value};
    }
    return 1;
}

sub fix_errata {
    my ($s, $r) = @_;
    my $uri = $r->{uri} or return 0;
    my $i = $s->{e}->{$uri} or return 1;
    _fix_items($i, $r);
    return 1;
}

sub _items_okay {
    my ($e, $r) = @_;

    my @o;
    for (keys %{ $r }) {
        my $d = $e->{$_} or next;
        my $do_next_level = 0;
        for my $k (keys %{ $d }) {
            next if grep $k eq $_, qw(alias value);
            $do_next_level = 1;
        }
        if ($do_next_level) {
            my $o1 = _items_okay($d, $r->{$_});
            push @o, @{ $o1 } if $o1;
            next;
        }

        my $kv = 0;
        for my $k (qw(alias value)) {
            $kv++ if grep $_ eq $k, keys %{ $d };
        }
        next unless $kv == 2;
        next unless $d->{alias} eq $r->{$_};
        push @o, $_ if $d->{value} eq '_DIFF_OKAY_';
    }
    return @o ? \@o : undef;
}

sub diff_okay {
    my ($s, $r) = @_;
    my $uri = $r->{uri} or return undef;
    my $i = $s->{e}->{$uri} or return undef;
    my $o = _items_okay($i, $r);
    return $o;
}

1;
