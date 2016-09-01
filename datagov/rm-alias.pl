#!/usr/bin/env perl

use Getopt::Long qw/GetOptions/;
use Pod::Usage qw/pod2usage/;

use Gcis::Client;
use Data::Dumper;
use YAML::XS qw/Dump Load/;

use strict;
use v5.14;

my $n_max = -1;
my $update = 1;
my $url = qq(https://data.gcis-dev-front.joss.ucar.edu);
my $lexicon = 'datagov';
my $context = 'Organization';
# my $url = qq(https://data-stage.globalchange.gov);

&main;

sub main {

    my $g = $update ? Gcis::Client->connect(url => $url)
                    : Gcis::Client->new(url => $url);

    my @d;
    my $e = load_list();
    my $r;

    my $i = 0;
    for (@{ $e }) {
        # say " $i :".Dumper($_);

        rm_alias($g, $_);

        $i++;
        last if $i >= $n_max  &&  $n_max > 0;
    }

    exit;
}

sub load_list {
    my $yml = do { local $/; <> };
    my $e = Load($yml);

    return \@$e;
}


sub rm_alias {
    my ($g, $a) = @_;

    my $t = $a->{term};
    my $i = $a->{gcid};

    # say " t : $t";
    # say " i : $i";

    my $c = $context;
    my $l = "/lexicon/$lexicon";

    my $v = $g->get("$l/$c/$t");
    # say " v :".Dumper($v);
    if (!$v) {
        say " warning - term does not exist : $t";
        return;
    }
    my $u = $v->{uri};
    # say " u : $u";
    if ($i != $u) {
        say " warning - gcid does not match uri : $u";
        return;
    }

    if (!$update) {
        say " would remove term : $t";
        return;
    }

    say " removing term : $t";
    my $v = {
        term => $t,
        context => $c,
        };
    $g->delete("$l/$c/$t") or do {
        say " warning - error removing term : $t";
        return;
    };

    return;
}
