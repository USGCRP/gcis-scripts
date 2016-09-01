#!/usr/bin/env perl

use Getopt::Long qw/GetOptions/;
use Pod::Usage qw/pod2usage/;

use Gcis::Client;
use Data::Dumper;
use YAML::XS qw/Dump Load/;

use strict;
use v5.14;

my $n_max = 1;
my $update = 1;
# my $url = qq(https://data.gcis-dev-front.joss.ucar.edu);
my $url = qq(https://data-stage.globalchange.gov);
# my $url = qq(http://data.globalchange.gov);

&main;

sub main {

    my $g = $update ? Gcis::Client->connect(url => $url)
                    : Gcis::Client->new(url => $url);

    my $a = $g->get('/lexicon/govman/list/agencyName');
    my $ac = $g->get('/lexicon/govman/list/Agency');
    my %al = map { $_->{gcid} => $_->{term} } @{ $ac };

    my $i = 0;
    for (@{ $a }) {
        my $t = $_->{term};
        my $id = $_->{gcid};
        # say " t : $t";

        if (my $b = $g->get("/lexicon/datagov/Organization/$t")) { 
            my $j = $b->{uri};
            next if $id ne $j;
            say " removing dup 1 : $t";
            my $d = $g->delete("/lexicon/datagov/Organization/$t") or next;
            $i++; $i < $n_max or last;
        }
        
        my $t1 = "$t ($al{$id})";
        my $b1 = $g->get("/lexicon/datagov/Organization/$t1") or next;
        say " t1 : $t1";
        my $j1 = $b1->{uri};
        next if $id ne $j1;
        say " removing dup 2 : $t1";
        my $d = $g->delete("/lexicon/datagov/Organization/$t1") or next;
        $i++; $i < $n_max or last;
    }
    exit;

}
