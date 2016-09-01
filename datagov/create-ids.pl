#!/usr/bin/env perl

use Getopt::Long qw/GetOptions/;
use Pod::Usage qw/pod2usage/;

use Gcis::Client;
use Data::Dumper;
use YAML::XS qw/Dump Load/;
use Org;

use strict;
use v5.14;

my $n_max = 40;

my @nasa_orgs = (
    'national-aeronautics-space-administration',
    'national-snow-ice-data-center-distributed-active-archive-center',
    'oak-ridge-national-laboratory-distributed-active-archive-center',
);

my @nasa_daacs = qw(NSIDC ORNL LARC SEDAC LANCE GSFC);

# my $url = qq(https://data.gcis-dev-front.joss.ucar.edu);
my $url = qq(https://data-stage.globalchange.gov);
# my $url = qq(http://data.globalchange.gov);

&main;

sub main {

    my $g = Gcis::Client->new(url => $url);
    my $o = Org->new($g);

    my $r = load_list();

    my @d;
    my $i = 0;
    for (sort keys %$r) {
        $i++;
        last if $n_max > 1  &&  $i > $n_max;
        my $n = $_;
        my $c = $r->{$n};
        my $v = $c->{organization};
        my $u = $o->uri($v) or next;
        next unless grep $u eq "/organization/$_", @nasa_orgs;
        next unless $c->{landingPage} =~ /reverb/;
        if (!(grep $c->{landingPage} =~ "@_", @nasa_daacs)) {
           " warning - not a NASA DAAC : $c->{landingPage}";
           next;
        }

        my %s;
        $s{name} = $n;
        $s{organization} = $v;
        $s{uri} = $u; 
        $s{echoId} = $c->{idAgency};
        $s{landingPage} = $c->{landingPage};
        
        push @d, \%s;
    }
    say Dump(\@d);
}

sub load_list {

    my $yml = do { local $/; <> };
    my $e = Load($yml);
    my %r;
    for (@$e) {
        my $n = $_->{_ckan}->{name};
        if (!$n) {
           say " warning : null name";
           next;
        }
        if (%r{$n}) {
           say " error : duplicate name";
           exit;
        }
        $r{$n} = undef;

        my $o = $_->{_poc_org};
        $o =~ s/^'+//;
        $o =~ s/'+$//;
        $o =~ s/^\s+//;
        $o =~ s/\s+$//;
        $r{$n}->{organization} = $o;

        my $b = $_->{_ckan}->{bureauCode};
        $b =~ s/^\s+//;
        $b =~ s/\s+$//;
        $r{$n}->{bureauCode} = $b;

        $r{$n}->{idAgency} = $_->{_ckan}->{idAgency};
        $r{$n}->{landingPage} = $_->{_ckan}->{landingPage};
    }

    return \%r;
}
