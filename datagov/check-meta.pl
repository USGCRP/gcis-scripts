#!/usr/bin/env perl

use Gcis::Client;
use Iso;
use YAML::XS qw/Dump Load/;
use Data::Dumper;
use v5.18.2;

my $max_iter = -1;
my $url = qq(http://data.globalchange.gov);
my @nasa_org = qw(NSIDC GESDISC LPDAAC ORNL_DAAC LAADS);

my @ex = qw(
    C1840-NSIDCV0
    C179126625-ORNL_DAAC
    C191079401-NSIDC_ECS
    C1000000940-NSIDC_ECS
    C207169865-GSFCS4PA
    C197265171-LPDAAC_ECS
    );

my $compare_say_same = 1;

my $yml = do { local $/; <> };
my $l = Load($yml);
my @m;
my $n;

my $g = Gcis::Client->new(url => $url);

for (@{ $l }) {
    my $i = $_->{_identifier};
    next unless grep $i eq $_, @ex;
    # say " l :\n".Dumper($_);
    my $o = $_->{_poc_org};
    next unless grep $o eq $_, @nasa_org;

    my $d = $g->get($_->{uri}) or do {
        say " $_->{uri} not found";
        next;
    };
    # say " d :\n".Dumper($d);
 
    my $c = compare($_, $d);
    my $co = compare_org($_, $d);
    $c->{$_} = $co->{$_} for keys %$co;

    $c->{nasa_id} = $i;
    push @m, $c;

    $n++;
    next if $max_iter < 0;
    last if $n >= $max_iter;
}
say Dump(\@m);

sub compare {
    my ($a, $b) = @_;

    my %c;

    for (keys %$a) {
        next if $_ =~ /^_/;
        next if $b->{$_};
        next unless defined $a->{$_};
        if (ref $a->{$_} eq 'ARRAY') {
            next unless @{ $a->{$_} } > 0;
        } elsif (ref $a->{$_} eq 'HASH') {
            next unless %{ $a->{$_} } > 0;
        }
        $c{$_} = {only_a => $a->{$_}};
    }

    for (keys %$b) {
        next if $_ =~ /^_/;
        my $k = $_;
        next if grep $k eq $_, qw(href aliases contributors 
                                  instrument_measurements);
        next if $a->{$_};
        next unless defined $b->{$_};
        if (ref $b->{$_} eq 'ARRAY') {
            next unless @{ $b->{$_} } > 0;
        } elsif (ref $b->{$_} eq 'HASH') {
            next unless %{ $b->{$_} } > 0;
        }
        $c{$_} = {only_b => $b->{$_}};
    }

    my @common_keys = grep $b->{$_}, keys %$a;
    for (@common_keys) {
        next if $_ =~ /^_/;
        if (diff($_, $a->{$_}, $b->{$_})) {
            $c{$_} = {diff_a => $a->{$_}, diff_b => $b->{$_}};
        } else {
            $c{$_} = {same => $a->{$_}} if $compare_say_same;
        }
    }
    return %c ? \%c : 0;
}

sub diff {
     my ($k, $a, $b) = @_;
     return 0 if $a eq $b;
     if (grep $k eq $_, qw(lat_min lat_max lon_min lon_max)) {
        return 0 if abs ($a - $b) < 0.0005;
     }
     if (grep $k eq $_, qw(start_time end_time)) {
        $a =~ s/Z$//;
        $b =~ s/Z$//;
        return 0 if $a eq $b;
     }
     if ($k eq 'description') {
        $a =~ s/^ABSTRACT: //;
        $b =~ s/^ABSTRACT: //;
        return 0 if $a eq $b;
     }
     return 1;
}

sub compare_org {
    my ($a, $b) = @_;
    my %c;

    my $oa = $a->{_organization_uri};
    my $cb = $b->{contributors};

    my $ob;
    for (@$cb) {
        if ($ob) {
            say " error - more than one org b";
            next;
        }
        # say " con b:\n".Dumper($_);
        $ob = $_->{organization_uri};
        say " error - have person uri in org b" if $_->{person_uri};
    }
    my $v;
    if ($oa && !$ob) {
        $v = {only_a => $oa};
    } elsif (!$oa && $ob) {
        $v = {only_b => $oa};
    } elsif ($oa ne $ob) {
        $v = {diff_a => $oa, diff_b => $ob};
    } elsif ($compare_say_same) {
        $v = {same => $oa};
    }
    $c{organization} = $v if $v;
    
    return %c ? \%c : 0;
}
