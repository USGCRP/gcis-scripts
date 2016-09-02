#!/usr/bin/env perl

use Getopt::Long qw/GetOptions/;
use Pod::Usage qw/pod2usage/;

use Gcis::Client;
use Data::Dumper;

use strict;
use v5.14;

my $url = qq(https://data-stage.globalchange.gov);

&main;

sub main {

    my $e = load_list();

    my $g = Gcis::Client->new(url => $url);

    my $p = "/lexicon/datagov/dataset/";
    for (@$e) {
        my $a = $g->get($p.$_);
        if ($a) {
            say "$_\t$a->{identifier}";
            next;
        }
        say "$_\tnot_in_gcis";
    }

}

sub load_list {
    my @e;
    while (<>) {
       chomp;
       last if $_ eq '';
       push @e, $_;
    }

    return \@e;
}
