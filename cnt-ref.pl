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

=item B<--local>

Directory to store file (defaults to ".")

=back

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

    my $r = $g->get("$res$do_all") or die " no resource";
    if (ref $r ne 'ARRAY') {
       $r = [$r];
    }

    my $n = 0;
    my $nr = 0;
    my $m = 0;
    my %refs;
    for (@{ $r }) {
        my $u = $_->{uri};
        $n++;
        my $id = $_->{identifier};

        my $ref = $g->get("$u/reference.json$do_all") or do {
          say " $id : error";
          next;
        };
        my $nref = scalar @{ $ref };
        next if $nref == 0;
        map {$refs{$_->{uri}}++} @{ $ref };
        say " $id : $nref";
        $m += $nref;
        $nr++;
    }

    my $mu = keys %refs;
    say "";
    say " $res : $n";
    say " total : $m";
    say " unique : $mu";
    say " have ref : $nr";

    say " done";
    return;
}

1;

