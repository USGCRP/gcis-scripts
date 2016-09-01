#!/usr/bin/env perl

use Getopt::Long qw/GetOptions/;
use Pod::Usage qw/pod2usage/;

use Gcis::Client;
use Data::Dumper;
use YAML::XS qw/Dump Load/;
use Org;

use strict;
use v5.14;

my $url = qq(http://data-review.globalchange.gov);

&main;

sub main {

    my $g = Gcis::Client->new(url => $url);
    my $o = Org->new($g);

    my @d;
    my $r = load_list();

    my $i = 0;
    for (sort keys %$r) {
        my $n = $_ or next;
        my $v->{_name} = $n;
        $v->{_bureau_code} = $r->{$n} if $r->{$n};
        my $u = $o->uri($n); 
        if ($u) {
            $v->{uri} = $u;
            my $x = $g->get($u) or do {
                 say " error - uri not found : $u";
                 next;
            };
            $v->{name} = $x->{name};
        } else {
            $v->{_strip} = $o->strip($n);
        }

        Dumper($v);    
        push @d, $v;
        # last if $i >= 10;
        $i++;
    }
    say Dump(\@d);
}

sub load_list {

    my $yml = do { local $/; <> };
    my $e = Load($yml);
    my %r;
    for (@$e) {
        # say " e :\n".Dumper($_);
        $a = $_->{_poc_org};
        chomp $a;
        $a =~ s/ +&amp; +/ and /g;
        $a =~ s/\s+/ /g;
        $a =~ s/^'+//g;
        $a =~ s/'+$//g;
        $a =~ s/ +$//g;
        $a =~ s/^ +//g;
        $r{$a} = undef;

        $b = $_->{_ckan}->{bureauCode} or next;
        chomp $b;
        $b =~ s/\s+$//g;
        $b =~ s/^\s+//g;
        $r{$a} = $b;
    }

    return \%r;
}
