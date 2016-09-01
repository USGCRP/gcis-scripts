#!/usr/bin/env perl

use Getopt::Long qw/GetOptions/;
use Pod::Usage qw/pod2usage/;

use Gcis::Client;
use Data::Dumper;

use strict;
use v5.14;

my $acro = qq(common_agency_acronyms.txt);
my $url = qq(http://data-stage.globalchange.gov);

# either full, csv-full, csv-short, agency, name or undef
my $list_acro = 'agency';  

&main;

sub main {

    my $g = Gcis::Client->new(url => $url);

    my $a_list = load_acro($acro);

    if ($list_acro eq 'csv-long') {
        say "acronym,name,uri";
    } elsif ($list_acro eq 'csv-short') {
        say "acronym,uri";
    }

    for (sort keys %{ $a_list }) {
        my $a = $a_list->{$_};
        my $o = $g->get($a->{uri});
        if ($o) {
            $a->{gcis_name} = $o->{name};
        }
        if ($list_acro eq 'full') { 
            say " $_ :";
            say "     $_ : $a->{$_}" for keys %{ $a };
        } elsif ($list_acro eq 'csv-full') {
            my $g = $a->{uri} if $a->{gcis_name};
            say "$_,\"$a->{name}\",$g";
        } elsif ($list_acro eq 'csv-short') {
            my $g = $a->{uri} if $a->{gcis_name};
            say "$_,$g";
        } elsif ($list_acro eq 'agency') {
            next unless $a->{gcis_name};
            say "$_ : $a->{uri}";
        } elsif ($list_acro eq 'name') { 
            next unless $a->{gcis_name};
            say "$a->{name} : $a->{uri}";
        }
    }
}

sub load_acro {
    my $f = shift;
    open my $f, '<', $f or die "can't open acronym file : $f";
    my %a;
    my $k;
    my $o;
    for (<$f>) {
        chomp;
        next if /^#/;
        if (!$k) {
            $k = $_;
            $o = undef;
            next;
        }
        if (/^o: /) {
          $o = title_case(s/^o: //); 
          next;
        }
        my $v = title_case($_);
        my $s = lc;
        $s =~ s/ +/ /g;
        $s =~ s/ (and|of|for|&) / /g;
        $s =~ s/ the / /g;
        $s =~ s/u\.s\. */us /g;
        $s =~ s/control prevention/control and prevention/;
        $s =~ s/\. / /g;
        $s =~ s/, / /g;
        $s =~ s/ /-/g;
        if ($o) {
            $a{$k}->{name} = $o;
            $a{$k}->{revised} = $v;
        } else {
            $a{$k}->{name} = $v;
        }
        $a{$k}->{uri} = "/organization/$s";
        # say " $k : $a{$k}->{uri}";
        $k = '';
    }
    return \%a;
}

sub title_case {
    s/ +/ /g;
    s/([^\s.,-]+)/\u\L$1/g;
    s/ (And|Of|For|In|Are|On|From|A) / \L$1 /g;
    s/ (The|A) / \L$1 /g;
    s/^(the|a) /\u\L$1 /;
    return $_;
}
