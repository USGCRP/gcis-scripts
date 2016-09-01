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

# my $url = qq(https://data.gcis-dev-front.joss.ucar.edu);
my $url = qq(https://data-stage.globalchange.gov);
# my $url = qq(https://data-review.globalchange.gov);
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
        my $b = $r->{$_};
        my $v = $o->uri($_);
        my $w;
        $w = "no uri : ".($o->strip($_)) unless $v;
        if ($v  &&  $b) {
            my $b1 = $o->bureau($v);
            if (!$b1) {
                $w = "no bureau code";
            } elsif ($b ne $b1) {
                $w = "bureau code different : $b1";
            }
        }

        my %s;
        $s{name} = $_;
        $s{bureau} = $b if $b;
        $s{uri} = $v if $v;
        $s{_warning} = $w if $w;
        
        push @d, \%s;
    }
    say Dump(\@d);
}

sub load_list {

    my $yml = do { local $/; <> };
    my $e = Load($yml);
    my %r;
    for (@$e) {
        # say " e :\n".Dumper($_);
        my $a;
        for my $o (qw(responsible-party publisher_hierarchy publisher organization)) {
            $a = $_->{$o} or next;
            last;
        }
        # chomp $a;
        $a =~ s/ +&amp; +/ and /g;
        $a =~ s/\s+/ /g;
        # $a =~ s/^'+//g;
        # $a =~ s/'+$//g;
        # $a =~ s/ +$//g;
        # $a =~ s/^ +//g;
        $r{$a} = undef;

        $b = $_->{_ckan}->{bureauCode} or next;
        # $b =~ s/^\s+//;
        # $b =~ s/\s+$//;
        $r{$a} = $b;
    }

    return \%r;
}
