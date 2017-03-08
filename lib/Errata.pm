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
        my $uri = $h->{uri} or do {
            say " h :\n".Dumper($h);
            die "no uri for item : $n";
        };
        ref $h->{errata} eq 'ARRAY' or 
            die "third level must be an array for $uri";
        my $a = _load_array($h->{errata}) or die "invalid array values for $uri";
        if (!$e->{$uri}) {
            @{ $e->{$uri} } = $a;
        } else {
            push @{ $e->{$uri} }, $a;
        }
    }

    return $e;
}

sub _fix_items {
    my ($errata, $resource) = @_;
    for my $resource_key (keys %{ $resource }) {
        my $errata_item = $e->{$resource_key} or next;
        my $kv = 0;
        for my $k (qw(alias value)) {
            $kv++ if grep $k eq $_, keys %{ $errata_item };
        }
        if ($kv == 0) {
            _fix_items($errata_item, $resource->{$resource_key});
            next;
        }
        next unless $kv == 2;
        next unless $errata_item->{alias} eq $resource->{$resource_key};
        next if $errata_item->{value} eq '_DIFF_OKAY_';
        $resource->{$resource_key} = $errata_item->{value};
    }
    return 1;
}

sub fix_errata {
    my ($self, $resource) = @_;
    #say STDOUT "DEBUG: IN Fix Errata!";
    my $uri = $resource->{uri} or return 0;
    #say "DEBUG: Found A Resourse URI";
    my $uri_errata = $self->{e}->{$uri} or return 1;
    #say "DEBUG: Found An Errata URI";
    for (@{ $uri_errata }) {
        #say "Fixing Errata! Here's the _ for array { i }:";
        #say Dumper $_;
        _fix_items($_, $resource);
    }
    return 1;
}

sub _items_okay {
    my ($errata, $resource) = @_;

    my $o;
    for my $resource_key (keys %{ $resource }) {
        my $errata_item = $errata->{$resource_key} or next;
        my $kv = 0;
        for my $k (qw(alias value)) {
            $kv++ if grep $k eq $_, keys %{ $errata_item };
        }
        if ($kv == 0) {
            my $o1 = _items_okay($errata_item, $resource->{$resource_key});
            $o->{$_} = 1 for keys %{ $o1 };
            next;
        }
        next unless $kv == 2;
        next unless $errata_item->{alias} eq $resource->{$resource_key};
        $o->{$resource_key} = 1 if $errata_item->{value} eq '_DIFF_OKAY_';
    }
    return $o ? $o : undef;
}

sub diff_okay {
    my ($self, $resource) = @_;
    my $uri = $resource->{uri} or return undef;
    my $item_errata = $self->{e}->{$uri} or return undef;
    my $o;
    for (@{ $item_errata }) {
        my $o1 = _items_okay($_, $resource);
        $o->{$_} = 1 for keys %{ $o1 };
    }
    return $o;
}

1;
