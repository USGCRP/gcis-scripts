#!/usr/bin/env perl

=head1 NAME

add_tables_from_json.pl -- add tables from tsu json

=head1 DESCRIPTION

add_tables_from_json.pl adds tables to GCIS.

If the table exists, the 'update' flag will determine
if the new field values are applied.

=head1 SYNOPSIS

./add_tables_from_json.pl [OPTIONS]

=head1 OPTIONS

=over

=item B<--url>

GCIS url, e.g. https://data-stage.globalchange.gov

=item B<--file>

File containing the references with keys to update

=item B<--update>

Whether to overwrite existing table fields or only add new ones

=item B<--verbose>

Verbose option

=item B<--dry_run>

Set to perform dry run (no actual update)

=back

=head1 EXAMPLES


  # Only add new tables
  ./add_tables_from_json.pl \
    --url https://data-stage.globalchange.gov \
    --file chapter_5_kf.json

  # Add new tables and overwrite existing table fields
  ./add_tables_from_json.pl \
    --url https://data-stage.globalchange.gov \
    --file chapter_5_kf.json \
    --update

  Example input file (json format):

  [
    {
      "ordinal": 1,
      "identifier": "historic-and-decadal-global-mean-emissions-and-their-partitioning-to-the-carbon-reservoirs-of-atmosphere-ocean-and-land",
      "chapter_name": "overview-of-the-global-carbon-cycle",
      "report": "second-state-carbon-cycle-report-soccr2-sustained-assessment-report",
      "title": "Historic (a) and Decadal (b) Global Mean Emissions and Their Partitioning to the Carbon Reservoirs of Atmosphere, Ocean, and Land"
    },
    {
    ...
    }
  ]

=cut

use Getopt::Long qw/GetOptions/;
use Pod::Usage qw/pod2usage/;

use Gcis::Client;
use Data::Dumper;
use Mojo::JSON qw(decode_json);

use strict;
use v5.14;

GetOptions(
  'url=s'     => \(my $url),
  'file=s'    => \(my $file),
  'update'   => \(my $update),
  'verbose'   => \(my $verbose),
  'very_verbose' => \(my $very_verbose),
  'dry_run|n' => \(my $dry_run),
  'help|?'    => sub { pod2usage(verbose => 2) },
) or die pod2usage(verbose => 1);

pod2usage(msg => "missing url", verbose => 1) unless $url;
pod2usage(msg => "missing file", verbose => 1) unless $file;


&main;

sub main {

    say "Add Tables to GCIS";
    say " url : $url";
    say " file : $file";
    say " update existing on" if $update;
    say " verbose on" if $verbose;
    say " very verbose on" if $very_verbose;
    say " dry run" if $dry_run;

    $verbose = 1 if $very_verbose;

    my $gcis = $dry_run ? Gcis::Client->new(url => $url) :
                       Gcis::Client->connect(url => $url);

    my $tables = load_data($file);
    foreach my $table ( @$tables ) {

        my $chapter = $table->{chapter_name};
        my $report = $table->{report};
        my $gcis_report = $gcis->get("/report/$report");
        unless ( $gcis_report ) {
            say " Report $report does not exist";
            next;
        }
        my $gcis_chapter = $gcis->get("/report/$report/chapter/$chapter");
        unless ( $gcis_chapter ) {
            say " Chapter $chapter does not exist";
            next;
        }

        say "---";
        say " table: $table->{identifier}";
        # Pull GCIS table
        my $table_uri = "/report/$report/chapter/$chapter/table";
        say " checking: $table_uri/$table->{identifier}";
        my $gcis_table = $gcis->get("$table_uri/$table->{identifier}");
        if ( ! $gcis_table ) {
            say " New table to GCIS" if $verbose;
        }
        else {
            say " Existing table to GCIS" if $verbose;
            say " gcis table :\n".Dumper($gcis_table) if $very_verbose;
            unless ( $update ) {
                say "   Not updating existing table";
                next;
            }
            say "   Updating existing table";
            $table_uri = "/report/$report/chapter/$chapter/table/$table->{identifier}";
        }
        my $table_postdata = build_table($table);
        post_table($table_uri, $gcis, $table_postdata);
    }
    say "done";
}

sub load_data {
    my $file = shift;

    open my $f, '<', $file or die "can't open file : $file";

    my $json = do { local $/; <$f> };
    my $tables = decode_json($json);

    return $tables;
}

sub build_table {
    my ($table, $process, $report, $chapter) = @_;

    my $post_data = {
        identifier            => $table->{identifier},
        report_identifier     => $table->{report},
        chapter_identifier    => $table->{chapter_name},
        ordinal               => $table->{ordinal},
        title                 => $table->{title},
    };

    return $post_data;
}


sub post_table {
    my ($uri, $gcis, $table_postdata) = @_;

    say " table to post :\n".Dumper($table_postdata) if $very_verbose;

    if ($dry_run) {
        say "DRYRUN: would post table to : $table_postdata->{identifier}";
        return 0;
    }

    say " Posting table for : $uri";
    $gcis->post($uri, $table_postdata) or 
        warn " unable to post table for : $table_postdata->{identifier}";

    return 1;
}
