#!/usr/bin/env perl

use Getopt::Long qw/GetOptions/;
use Pod::Usage qw/pod2usage/;

use Gcis::Client;
use Data::Dumper;
use YAML::XS qw/Dump Load/;
use Org;

use strict;
use v5.14;

my $n_max = -1;
my $max_update = -1;
my $dry_run = 1;
# my $url = qq(https://data.gcis-dev-front.joss.ucar.edu);
# my $url = qq(https://data-review.globalchange.gov);
my $url = qq(https://data-stage.globalchange.gov);

my $test = 0;
my %ex = (
  '/dataset/nasa-gesdisc-nldas-for0125-h-001' => 1,
  '/dataset/nasa-nsidcdaac-imcs30' => 0,
  '/dataset/noaa-ncdc-c00824' => 0,
  '/dataset/nasa-ornldaac-1078' => 0,
  '/dataset/nasa-ornldaac-705' => 0, 
  '/dataset/nasa-nsidcdaac-0169' => 0,
  '/dataset/nsidc-g02172' => 0,
  '/dataset/nasa-nsidcdaac-brmcr2' => 0, 
  '/dataset/nsidc-g02189' => 0, 
  '/dataset/nasa-nsidcdaac-gla12' => 0,
  '/dataset/nasa-nsidcdaac-iodms1b' => 0,
  '/dataset/nasa-nsidcdaac-idhdt4' => 0, 
  );

my %map = (
    describedBy => 'description_attribution', 
    landingPage => 'url', 
    downloadURL => 'url', 
    notes => 'description',
    'spatial.lat_max' => 'lat_max',
    'spatial.lat_min' => 'lat_min',
    'spatial.lon_max' => 'lon_max',
    'spatial.lon_min' => 'lon_min',
    'temporal.start_time' => 'start_time', 
    'temporal.end_time' => 'end_time',
    title => 'name',
    );

my $n_update = 0;
&main;

sub main {

    my $g = $dry_run ? Gcis::Client->new(url => $url)
                     : Gcis::Client->connect(url => $url);

    my @d;
    my $e = load_list();

    my $c = load_list('connect_ids.yaml');
    my %m = map { $_->{identifier} => {
                    gcid => $_->{gcid}, 
                    dataset => $_->{dataset} } } @$c;

    my $n = 0;
    for (@$e) {
        last if $n_update >= $max_update  &&  $max_update > 0;
        $n++;
        last if $n > $n_max  &&  $n_max > 0;
        my $i = $_->{idDataGov};
        if (!$m{$i}) {
            say " warning - missing gcid for $i";
            next;
        }
        $_->{gcid} = $m{$i}->{gcid};
        if ($test) { next unless $ex{$_->{gcid}}; }
        say " name : $_->{name}";
        put_meta($g, $_) or next;
        put_lex($g, $_) or next;
        put_org($g, $_);
    }

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

sub put_meta {
    my ($g, $d) = @_;

    my $i = $d->{gcid};
    say "   gcid : $i";
    my $c = $g->get($i);
    my $exists = defined $c;
    if ($exists) {
        say "   dataset exists";
        update_dataset($d, $c) or return 1;
    } else {
        say "   dataset does not exist";
        $c = create_dataset($d) or return 0;
    }

    if ($dry_run) {
        say "   would ".($exists ? 'update' : 'create')." : $i";
        $n_update++;
        return 0;
    }

    if (!$exists) {
        $c->{identifier} = $i;
        $c->{identifier} =~ s[^/dataset/][];
        $g->post("/dataset", $c) or do {
            say " error - creating : $i";
            return 0;
        }
    } else {
        $g->post($i, $c) or do {
            say " error - updating : $i";
            return 0;
        }
    };
    say "   ".($exists ? 'updated' : 'created')." : $i";

    $n_update++;

    return 1;
}

sub put_org {
    my ($g, $d) = @_;

    my $o;
    for (qw(responsible-party publisher_hierarchy publisher organization)) {
        $o = $d->{$_} or next;
        last;
    }
    $o =~ s/ +&amp; +/ and /g;
    $o =~ s/\s+/ /g;
    my $org = Org->new($g) or 
        die " error - org new";

    my $u = $org->uri($o) or do {
        say "   no organization found : $o";
        return 0;
    };

    my $i = $d->{gcid};
    my $c = $g->get($i) or do {
        say " error - no dataset";
        return 0;
    };

    my $found = 0;
    my $diff;
    if ($c->{contributors}) {
        for (@{ $c->{contributors} }) {
            next unless $_->{organization_uri};
            next unless $_->{role_type_identifier} eq 'data_archive';
            if ($_->{organization_uri} ne $u) {
                $diff = $_->{organization_uri};
                next;
            }
            $found = 1;
        }
    }
    if ($found) {
        say "   organization exists";
        return 1;
    }
    if ($diff) {
        say "   no update - different organization exists";
        say "     current : $diff";
        say "     new     : $u";
        return 0;
    }

    if ($dry_run) {
        say "   would assign organization : $u";
        $n_update++;
        return 0;
    }

    say "   assigning organization : $u";
    $i =~ s[^/dataset/][/dataset/contributors/];
    $g->post($i => 
        { organization_identifier => $u,
          role => 'data_archive'}) or do {
        say " error - assigning organziation";
        return 0;
    };
    $n_update++;
    return 1;
}

sub put_lex {
    my ($g, $d) = @_;

    my $l = "/lexicon/datagov";
    my %m = ( idDataGov => 'identifier', name => 'dataset' );
    my $i = $d->{gcid};

    for (keys %m) { 
        my $t = $d->{$_} or do {
            say "   no term : $_";
            return 0;
        };

        if (my $c = $g->get("$l/$m{$_}/$t")) {
            if ($c->{uri} ne $i) {
                say "   no update - different term already exists";
                say "     current : $c->{uri}";
                say "     new     : $i";
                return 0;
            }
            say "   term exists : $t";
            next;
        }

        if ($dry_run) {
            say "   would assign term : $t";
            $n_update++;
            next;
        }

        say "   assigning term : $t";
        my $v = {
            term => $t,
            context => $m{$_},
            gcid => $i,
        };

        $g->post("$l/term/new", $v) or do {
            say " error - posting new term : $t";
            next;
        };
        $n_update++;
    }
    return 1;
}

sub create_dataset {
    my $d = shift;

    my %c;
    for (keys %map) {
        my $m = $map{$_};
        next if (%c{$m});
        my $v;
        if ($_ =~ /(\w+)\.(\w+)/) {
           $v = $d->{$1}->{$2} or next;
        } else {
           $v = $d->{$_} or next;
        }
        $v =~ s/^[\s'"]+//;
        $v =~ s/[\s'"]+$//;
        $v =~ s/^<p>\s*//;
        $v =~ s/\s*<\/p>$//;
        $v =~ s/\n/ /g;
        $v =~ s/ +/ /g;
        if ($m =~ /^(start|end)_time$/) {
           $v =~ s/Z$//;
        }
        $c{$m} = $v;
    }
    return \%c;
}

sub update_dataset {
    my $d = shift;
    my $c = shift;

    my $v = create_dataset($d);

    my $new = 0;
    my $diff = 0;
    for (keys %$v) {
        if (!defined $c->{$_}) {
            $c->{$_} = $v->{$_};
            $new = 1;
            say "   new : $_";
            say "     value : $c->{$_}";
            if ($_ eq 'end_time') {
                say "     not updated";
                $new = 0;
            }
            next;
        }
        next if $c->{$_} eq $v->{$_};
        if ($_ =~ /(start|end)_time/) {
            next unless temporal_diff($c->{$_}, $v->{$_});
        } elsif ($_ =~ /(lon|lat)_(min|max)/) {
            next if $c->{$_} == $v->{$_};
        }
        if ($_ eq 'description') {
            my $a = ($c->{$_} =~ s/^abstract: //ir);
            next if $a eq $v->{$_};
        }
        say "   different : $_";
        say "     current : $c->{$_}";
        say "     new :     $v->{$_}";
        $diff++;
    }
    return 0 unless $new;

    delete $c->{$_} for qw/aliases contributors cited_by 
                           display_name files href 
                           instrument_measurements parents 
                           references type uri/;
    for (keys %$c) {
        next if defined $c->{$_};
        delete $c->{$_};
    }
    # say " c :\n".Dumper($c);

    return 1;
}

sub temporal_diff {
    my ($a, $b) = @_;
    return 0 if $a eq $b;
    $_ =~ s/z$//i for $a, $b;
    return 0 if $a eq $b;
    $_ =~ s/\.0+$//i for $a, $b;
    return 0 if $a eq $b;
    return 1;
}
