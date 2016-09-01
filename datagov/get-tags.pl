#!/usr/bin/env perl

use Getopt::Long qw/GetOptions/;
use Pod::Usage qw/pod2usage/;

use Gcis::Client;
use Data::Dumper;
use YAML::XS qw/Load Dump/;

use strict;
use v5.14;

my $n_max = -1;
my $url = qq(https://data-stage.globalchange.gov);

&main;

sub main {

    my $g = Gcis::Client->new(url => $url);
    my @d;
    my $e = load_list();
    my $n = 0;
    my %c;
    for my $x (@$e) {
        $n++; 
        last if $n_max > 0  &&  $n > $n_max;
        my $v;
        for (qw(idDataGov tags)) {
            next unless $x->{$_};
            $v->{$_} = $x->{$_};
        }
        if ($v->{tags}) {
            $v->{tags} = uniq($v->{tags});
            $c{$_}++ for @{ $v->{tags} };
        }
        $a = $g->get("/lexicon/datagov/identifier/$v->{idDataGov}") or do {
            say " error - not in gcis : $v->{idDataGov}";
            next;
        };
        $v->{gcid} = "/dataset/$a->{identifier}";
        push @d, $v;
    }
    $n--;
    say " count (of $n)";
    say "   $_ : $c{$_}" for keys %c;
    say Dump(\@d);
    exit;
}

sub load_list {
    my $file = shift;

    my $yml;
    if ($file) {
        open my $f, '<', $file or die "can't open file : $file";
        $yml = do { local $/; <$f> };
        close $f;
    } else {
        $yml = do { local $/; <> };
    }
    my $e = Load($yml);

    return $e;
}

sub uniq {
    my $l = shift;
    my %c;
    my @u = grep { not $c{$_}++ } @$l;
    return \@u;
}
