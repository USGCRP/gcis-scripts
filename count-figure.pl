#!/usr/bin/env perl

use Getopt::Long qw/GetOptions/;
use Pod::Usage qw/pod2usage/;

use Gcis::Client;
use Gcis::Exim;
use YAML;
use Data::Dumper;

use strict;
use v5.14;

# local $YAML::Indent = 2;

GetOptions(
  'url=s'       => \(my $url), 
  'resource=s'  => \(my $res),
  'all'         => \(my $all),
  'help|?'      => sub { pod2usage(verbose => 2) },
) or die pod2usage(verbose => 1);

my $n = 0;
&main;

sub main {

    say " counting figures";
    say "     url : $url";
    say "     resource : $res";
    say "     all" if $all;
    say "";

    my $do_all = $all ? "?all=1" : undef;

    my $g = Gcis::Client->new(url => $url);

    my $r = $g->get("$res$do_all") or die " no resource";
    if (ref $r ne 'ARRAY') {
       $r = [$r];
    }

    my $n = 0;
    my $nfig = 0;
    my $m = 0;
    my %figs;
    for (@{ $r }) {
        my $u = $_->{uri};
        $n++;
        my $id = $_->{identifier};

        my $fig = $g->get("$u/figure$do_all") or do {
          say " $id : error";

          next;
        };
        my $nfig = scalar @{ $fig };
        next if $nfig == 0;
        map {$figs{$_->{uri}}++} @{ $fig };
        say " $id : $nfig";
        $m += $nfig;
        $nfig++;
    }
    my $nc = 0;
    my $nimg = 0;
    my $npar = 0;
    my $nact = 0;
    my $ndat = 0;
    for (keys %figs) {
        my $c = count_img($g, $_);
        next unless $c;
        #say "   nimg : $c->{nimg} ";
        $nimg += $c->{nimg};
        $npar += $c->{npar};
        $nact += $c->{nact};
        $ndat += $c->{ndat};
        $nc++;


        last if $nc >=20 ;
    }
    my $mu = keys %figs;
    say "";
    say " $res : $n";
    say " total : $m";
    say " unique : $mu";
    say " have fig : $nfig";
    say " total img : $nimg";
    say " total par : $npar";
    say " total act : $nact";
    say " total dat : $ndat";

    say " done";
    return;
}

sub count_img { 
    my $g = shift;
    my $f = shift;
    #say " f : $f"; 
    my $c;  
    my $fig = $g->get($f) or do {
        say " $f : error";
        return undef;
    };
    #say " fig : \n".Dumper($fig); 
    for (@{ $fig->{images} }) {
        my $a = count_act($g, "/image/$_->{identifier}");
        next unless $a;
        $c->{nimg}++;
        $c->{npar} += $a->{npar};
        $c->{nact} += $a->{nact};
        $c->{ndat} += $a->{ndat};
      
    }
    return $c;
}

sub count_act {
    my $g = shift;
    my $r = shift;
    #say " r : $r"; 
    my $c;
    my $res = $g->get($r) or do {
        say " $r : error";
        return undef;
    };
    #say " res : \n".Dumper($res);
    
    for (@{ $res->{parents} }) {
        $c->{npar}++;
        $c->{nact}++ if $_->{activity_uri};
        $c->{ndat}++ if $_->{url} =~ /^\/dataset\//;
    }    
    
    return $c;
}

1;

=head1 NAME

cnt-ref.pl -- count references for a resource

=head1 DESCRIPTION

cnt-ref -- Counts the references for a resource such as chapters in a 
report.

=head1 SYNOPSIS

./cnt-ref.pl [OPTIONS]

=head1 OPTIONS

=over

=item B<--url>

GCIS url, e.g. http://data.globalchange.gov

=item B<--resource>

GCIS resource, e.g. /report/nca3/chapter

=item B<stdout>

Count of references for the resource

=item B<--all>

Set to indicate all resources are to counted.

=item B<--local>

Directory to store file (defaults to ".")

=back

=head1 EXAMPLES

Count the number of references for the chapters in the nca3 report

./cnt-res.pl --url http://data.globalchange.gov
             --resouce /report/nca3/chapter  --all

=cut
