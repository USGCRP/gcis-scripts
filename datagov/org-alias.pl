#!/usr/bin/env perl

use Getopt::Long qw/GetOptions/;
use Pod::Usage qw/pod2usage/;

use Mojo::Util qw/url_escape/;
use Gcis::Client;
use Data::Dumper;
use YAML::XS qw/Dump Load/;

use strict;
use v5.14;

my $n_max = -1;
my $update = 1;
# my $url = qq(https://data.gcis-dev-front.joss.ucar.edu);
# my $url = qq(https://data-review.globalchange.gov);
my $url = qq(https://data-stage.globalchange.gov);

&main;

sub main {

    my $g = $update ? Gcis::Client->connect(url => $url)
                    : Gcis::Client->new(url => $url);

    my @d;
    my $e = load_list();
    my $r;

    my $i = 0;
    for (@{ $e }) {
        say " $i - $_->{term}";
        put_alias($g, $_);

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


sub put_alias {
    my ($g, $r) = @_;

    my $t = $r->{term} or do {
        say " error - no term";
        return;
    };
    my $i = $r->{gcid} or do {
        say " error - no gcid";
        return;
    };
    # $i = $url.$i;

    my $o = "Organization";
    my $p = "/lexicon/datagov";
    # say "   n : $n";

    my $v = $g->get("$p/$o/$t");
    # say " v :".Dumper($v);
    if ($v) {
        my $u = $v->{uri};
        say "   term exists : $u";
        if ($u ne $i) {
            " warning - gcid is different : $u";
        }
        return;

    }
    if (!$update) {
        say "   would add term : $t";
        return;
    }

    say "   adding term : $t";
    my $v = {
        term => $t,
        context => $o,
        gcid => $i,
        };
    # say " v :\n".Dumper($v);
    $g->post("$p/term/new", $v) or do {
        say " warning - error posting new term";
        return;
    };

    return;
}
