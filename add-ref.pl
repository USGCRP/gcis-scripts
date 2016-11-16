#!/usr/bin/env perl

=head1 NAME

add-ref.pl -- add a reference from yaml

=head1 DESCRIPTION

add-ref.pl adds a reference to GCIS

No change is made if the reference exists.

=head1 SYNOPSIS

./add-ref.pl [OPTIONS]

=head1 OPTIONS

=over

=item B<--url>

GCIS url, e.g. http://data-stage.globalchange.gov

=item B<--file>

File containing the reference to be created and the information

=item B<--verbose>

Verbose option

=item B<--dry_run>

Set to perform dry run (no actual update)

=back

=head1 EXAMPLES

./add-ref.pl -u http://data-stage.globalchange.gov < new_ref.yaml

Example input file (yaml format):

  ---
  - uri: /reference/6ca055db-9671-4dbc-9d65-aa72ac9e9510
    .place_published: 'Fairbanks, Alaska, USA'
    .publisher: Alaska Center for Climate Change Assessment and Policy
    .reference_type: 0
    Author: 'Lindsey, S.'
    Issue: Spring 2011
    Publication: Alaska Climate Dispatch
    Pages: 1-5
    Title: Spring breakup and ice-jam flooding in Alaska
    URL: http://accap.uaf.edu/sites/default/files/2011a_Spring_Dispatch.pdf
    Year: 2011
    _chapter: '["Ch. 22: Alaska FINAL"]'
    _record_number: 1583
    _uuid: 6ca055db-9671-4dbc-9d65-aa72ac9e9510
    reftype: 'Electronic Article'


=cut

use Getopt::Long qw/GetOptions/; use Pod::Usage qw/pod2usage/;

use Gcis::Client; use YAML::XS; use Data::Dumper; use Clone::PP qw(clone);

use strict; use v5.14;

GetOptions(
  'url=s'     => \(my $url),
  'file=s'    => \(my $file),
  'verbose'   => \(my $verbose),
  'dry_run|n' => \(my $dry_run),
  'help|?'    => sub { pod2usage(verbose => 2) },
) or die pod2usage(verbose => 1);

pod2usage(msg => "missing url", verbose => 1) unless $url;
pod2usage(msg => "missing file", verbose => 1) unless $file;

my $n_updates = 0;

&main;

sub main {

    say " adding reference";
    say " url : $url";
    say " file : $file";
    say " verbose on" if $verbose;
    say " dry run" if $dry_run;

    my $g = $dry_run ? Gcis::Client->new(url => $url) :
                       Gcis::Client->connect(url => $url);

    my $y = load_ref($file);
    say " uri: $y->[0]->{uri}";
    say " y :\n".Dumper($y) if $verbose;
    add_ref($g, $y->[0]);
    say "done";
}

sub load_ref {
    my $file = shift;

    open my $f, '<:encoding(UTF-8)', $file or die "can't open file : $file";

    my $yml = do { local $/; <$f> };
    my $y = Load($yml);

    return $y;
}

sub add_ref {
    my ($g, $u) = @_;

    my $uri = $u->{uri};
    if ($g->get($uri)) {
        say " reference already exist : $uri";
        return 0;
    };

    my $r = {
      attrs => $u->{attrs}, 
      identifier => $u->{identifier},
    };

    say " r :\n".Dumper($r) if $verbose;

    if ($dry_run) {
        say " would update reference for : $uri";
        return 0;
    }

    say " updating reference for : $uri";
    $g->post($r) or 
        die " unable to add reference for : $uri";

    $n_updates++;

    return 1;
}
