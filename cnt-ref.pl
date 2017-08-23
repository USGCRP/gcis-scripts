#!/usr/bin/env perl


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

=head1 EXAMPLES

Count the number of references for the chapters in the nca3 report

./cnt-res.pl --url http://data.globalchange.gov
             --resouce /report/nca3/chapter  --all

=cut


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

    say " counting references";
    say "     url : $url";
    say "     resource : $res";
    say "     all" if $all;
    say "";

    my $do_all = $all ? "?all=1" : undef;

    my $g = Gcis::Client->new(url => $url);

    my $resources = $g->get("$res$do_all") or die " no resource";
    if (ref $resources ne 'ARRAY') {
       $resources = [$resources];
    }

    my $num_resources = 0;
    my $resource_with_ref = 0;
    my $num_total_refs = 0;
    my %all_resources_refs;
    for my $resource (@{ $resources }) {
        my $resource_uri = $resource->{uri};
        $num_resources++;
        my $resource_id = $resource->{identifier};

        my $ref = $g->get("$resource_uri/reference.json$do_all") or do {
          say " $resource_id : error";
          next;
        };
        my $num_resource_refs = scalar @{ $ref };
        say sprintf("%-50s", $resource_id) . " : " . sprintf("%6s", $num_resource_refs);
        next if $num_resource_refs == 0;
        map {$all_resources_refs{$_->{uri}}++} @{ $ref };
        $num_total_refs += $num_resource_refs;
        $resource_with_ref++;
    }

    my $all_unique_references = keys %all_resources_refs;
    say "";
    say "For Resource(s) $res : ";
    say " Count of resources                      : " . sprintf("%6s", $num_resources);
    say " Resources with Non-Zero Reference Count : " . sprintf("%6s", $resource_with_ref);
    say " Total References across All Resources   : " . sprintf("%6s", $num_total_refs);
    say " Unique References across All Resources  : " . sprintf("%6s", $all_unique_references);

    say " done";
    return;
}

1;

