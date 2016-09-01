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
my $n_update = 0;
my $update = 1;
# my $url = qq(https://data.gcis-dev-front.joss.ucar.edu);
my $url = qq(https://data-review.globalchange.gov);

&main;

sub main {

    my $g = $update ? Gcis::Client->connect(url => $url)
                    : Gcis::Client->new(url => $url);

    my @d;
    my $e = load_list();
    my $r;

    for (@{ $e }) {
        last if $n_update >= $n_max  &&  $n_max > 0;

        say " gcid : $_->{gcid}";
        my $d; 
        $d->{dataset} = $_->{dataset}, 
        $d->{gcid} = $_->{gcid};
        put_alias($g, $d) or next;
        delete $d->{dataset};
        $d->{identifier} = $_->{identifier};
        put_alias($g, $d) or next;
    }

    exit;
}

sub load_list {
    my $yml = do { local $/; <> };
    my $e = Load($yml);

    return \@$e;
}


sub put_alias {
    my ($g, $d) = @_;

    my $o;
    for (keys %{$d}) {
        next if $_ eq 'gcid';
        $o = $_;
        last;
    }

    my $t = $d->{$o} or do {
        say " error - no $o";
        return 0;
    };
    my $i = $d->{gcid} or do {
        say " error - no gcid";
        return 0;
    };

    my $s = $g->get($i) or do {
        say " warning - gcid does not exist";
        return 0;
    };

    my $p = "/lexicon/datagov";

    my $v = $g->get("$p/$o/$t");

    if ($v) {
        my $u = $v->{uri};
        say "   $o exists : $u";
        if ($u ne $i) {
            " warning - gcid is different : $u";
        }
        return 0;

    }
    if (!$update) {
        say "   would add $o : $t";
        $n_update++;
        return 1;
    }

    say "   adding $o : $t";
    my $v = {
        term => $t,
        context => $o,
        gcid => $i,
        };

    $g->post("$p/term/new", $v) or do {
        say " warning - error posting new term";
        return 0;
    };
    $n_update++;

    return 1;
}
