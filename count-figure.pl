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

&main;

sub main {

    say " counting figures";
    say "     url : $url";
    say "     resource : $res";
    say "     all" if $all;
    say "";

    my $do_all = $all ? "?all=1" : undef;

    my $gcis_client = Gcis::Client->new(url => $url);

    say "Running Query :  $url$res$do_all\n";
    my $r = $gcis_client->get("$res$do_all") or die " no resource";
    #say Dumper $r;
    if (ref $r ne 'ARRAY') {
       $r = [$r];
    }

    my $num_resources = 0;
    my $num_figures = 0; # per resource
    my $total_figures = 0;
    my %figs;

    say " ID : Number of Figures";
    for (@{ $r }) {
        my $u = $_->{uri};
        $num_resources++;
        my $id = $_->{identifier};

        my $fig = $gcis_client->get("$u/figure$do_all") or do {
          say " $id : error";

          next;
        };
        my $num_figures = scalar @{ $fig };
        next if $num_figures == 0;
        map {$figs{$_->{uri}}++} @{ $fig };
        say " $id : $num_figures";
        $total_figures += $num_figures;
        $num_figures++;
    }
    my $num_images = 0;
    my $num_parents = 0;
    my $num_activities = 0;
    my $num_datasets = 0;
    for (keys %figs) {
        my $c = count_img($gcis_client, $_);
        next unless $c;
        #say "   num_images : $c->{num_images} ";
        $num_images += $c->{num_images};
        $num_parents += $c->{num_parents};
        $num_activities += $c->{num_activities};
        $num_datasets += $c->{num_datasets};
    }
    my $unique_figures = keys %figs;
    say "";
    say " $res    : $num_resources";
    say " total          : $total_figures";
    say " unique         : $unique_figures";
    say " have figure    : $num_figures";
    say " total image    : $num_images";
    say " total parents  : $num_parents";
    say " total activity : $num_activities";
    say " total dataset  : $num_datasets";

    say " done";
    return;
}

sub count_img { 
    my $gcis_client = shift;
    my $f = shift;
    #say " f : $f"; 
    my $c;  
    my $fig = $gcis_client->get($f) or do {
        say " $f : error";
        return undef;
    };
    #say " fig : \n".Dumper($fig); 
    for (@{ $fig->{images} }) {
        my $a = count_act($gcis_client, "/image/$_->{identifier}");
        next unless $a;
        $c->{num_images}++;
        $c->{num_parents} += $a->{num_parents};
        $c->{num_activities} += $a->{num_activities};
        $c->{num_datasets} += $a->{num_datasets};
      
    }
    return $c;
}

sub count_act {
    my $gcis_client = shift;
    my $r = shift;
    #say " r : $r"; 
    my $c;
    my $res = $gcis_client->get($r) or do {
        say " $r : error";
        return undef;
    };
    #say " res : \n".Dumper($res);
    
    for (@{ $res->{parents} }) {
        $c->{num_parents}++;
        $c->{num_activities}++ if $_->{activity_uri};
        $c->{num_datasets}++ if $_->{url} =~ /^\/dataset\//;
    }    
    
    return $c;
}

1;

=head1 NAME

count-figure.pl -- count figures for a resource

=head1 DESCRIPTION

count-figure -- Counts the figures for a resource such as chapters in a 
report.

=head1 SYNOPSIS

./count-figure.pl [OPTIONS]

=head1 OPTIONS

=over

=item B<--url>

Required, GCIS url, e.g. http://data.globalchange.gov

=item B<--resource>

Required, GCIS resource, e.g. /report/nca3/chapter. Empty string is acceptable.

=item B<stdout>

Count of references for the resource

=item B<--all>

Set to indicate all resources are to counted.

=back

=head1 EXAMPLES

Count the number of figures for the chapters in the nca3 report

./count-figure.pl --url http://data.globalchange.gov
             --resouce /report/nca3/chapter  --all

=cut
