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
    my $t = load_list('tags.yaml');
    my $n = 0;
    my $n = 0;
    my %c1;
    my %c2;
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
            $c1{$_}++ for @{ $v->{tags} };
            $v->{tags} = reduce($t, $v->{tags});
            $c2{$_}++ for @{ $v->{tags} };
        }
        $a = $g->get("/lexicon/datagov/identifier/$v->{idDataGov}") or do {
            say " error - not in gcis : $v->{idDataGov}";
            next;
        };
        $v->{gcid} = "/dataset/$a->{identifier}";
        push @d, $v;
    }
    $n--;
    say " full count (of $n)";
    say "   $_ : $c1{$_}" for sort keys %c1;
    say " reduced count (of $n)";
    say "   $_ : $c2{$_}" for sort keys %c2;
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

sub reduce {
    my $t = shift;
    my $v = shift;

    my %h;
    my %s;
    my @u;
    my @e;

    for (@$v) {
        if (exists $t->{$_}) {
            $h{$_}++;
            next;
        }
        my $is_subtheme = 0;
        for my $c (keys %$t) {
            next unless exists $t->{$c}->{$_};
            $s{$_} = $c;
            $is_subtheme = 1;
            last;
        }
        if (!$is_subtheme) {
            say " error - not in theme or sub-theme list : $_";
            push @e, "_error_not_found : $_";
            $s{$_} = undef;
        } 
    }
    for (keys %s) {
        next if exists $h{$s{$_}};
        say " error - no theme ($s{$_}) for sub-theme : $_";
        push @e, "_error_no_theme : $_";
    }
    delete $h{$s{$_}} for keys %s;
    # say " theme : $_" for keys %h;
    # say " sub-theme : $_ -> $s{$_}" for keys %s;
    push @u, $_ for (keys %h, keys %s);
    push @u, $_ for @e;

    return \@u;
}
