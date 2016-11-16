#!/usr/bin/env perl

=head1 NAME

export-yaml.pl -- Export items from GCIS to a yaml file

=head1 DESCRIPTION

export-yaml.pl exports sitems from GCIS to a yaml formated file.  The
output file can be read by export-yaml.pl.

Note that any relationships are exported.

*** This program has only been tested with "findings". ***

=head1 SYNOPSIS

./export-yaml.pl [OPTIONS]

=head1 OPTIONS

=over

=item B<--url>

GCIS url, e.g. http://data-stage.globalchange.gov

=item B<--file>

Output yaml formatted file containing GCIS items

=item B<--what>

GCIS resource (e.g. finding)

=item B<--report>

Report identifier

=item B<--chapter>

Chapter identifier (optional)

=item B<--all>

All option, unless this is set only top few items are read from GCIS

=item B<stdout>

Various log information is written to 'stdout'

=back

=head1 EXAMPLES

# write findings from GCIS to a yaml file:

./export-yaml.pl -u http://data-stage.globalchange.gov \
                 -w finding -r nca3 -c our-changing-climate \
                 -f findings.yaml -a

All of the findings from the from chapter 'our-changing-climate' in report 
'nca3' are written.

=cut

use Data::Dumper;
use Gcis::Client;
use YAML::XS;
use Getopt::Long;
use Pod::Usage;

use strict;
use v5.14;
use warnings;

GetOptions(
    'url=s'          => \(my $url),
    'file=s'         => \(my $file),
    'what=s'         => \(my $what),
    'report=s'       => \(my $report),
    'chapter=s'      => \(my $chapter),
    'all'            => \(my $all),
    'help|?'         => sub { pod2usage(verbose => 2) },
) or die pod2usage(verbose => 1);

pod2usage(msg => "missing url, yaml file, gcis resource or report identifier", 
          verbose => 1) unless ($url && $file && $what && $report);

say " exporting items from GCIS to yaml file";
say "   url : $url";
say "   file : $file";
say "   what : $what";
say "   report : $report";
say "   chapter : $chapter" if $chapter;
say "   all" if $all;
say '';

&main;

sub dump_yaml {
    my $file = shift or return 0;
    my $y = shift or return 0;
    open my $f, '>:encoding(UTF-8)', $file or die "can't open file : $file";
    say $f Dump($y);
    return 1;
}

sub main {
    my $g = Gcis::Client->new(url => $url);

    my $x = "/report/$report";
    $x .= "/chapter/$chapter" if $chapter;
    $x .= "/$what";
    $x .= '?all=1' if $all;
    my $l = $g->get($x) or die "gcis get failed";
    my $m = @{ $l };

    my $b = "report $report";
    $b = "chapter $chapter in $b" if $chapter;
    say " exporting $m $what(s) from $b";

    dump_yaml($file, $l) or die "dump failed";;

    exit;
}
