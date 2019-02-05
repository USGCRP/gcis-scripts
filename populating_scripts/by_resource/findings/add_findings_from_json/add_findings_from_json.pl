#!/usr/bin/env perl

=head1 NAME

add_findings_from_json.pl -- add findings from tsu json

=head1 DESCRIPTION

add_findings_from_json.pl adds findings to GCIS.

If the finding exists, the 'update' flag will determine
if the new field values are applied.

=head1 SYNOPSIS

./add_findings_from_json.pl [OPTIONS]

=head1 OPTIONS

=over

=item B<--url>

GCIS url, e.g. https://data-stage.globalchange.gov

=item B<--file>

File containing the references with keys to update

=item B<--report>

Which report these findings belong to, gcis identifier

=item B<--update>

Whether to overwrite existing finding fields or only add new ones

=item B<--verbose>

Verbose option

=item B<--dry_run>

Set to perform dry run (no actual update)

=back

=head1 EXAMPLES


  # Only add new findings
  ./add_findings_from_json.pl \
    --url https://data-stage.globalchange.gov \
    --file chapter_5_kf.json

  # Add new findings and overwrite existing finding fields
  ./add_findings_from_json.pl \
    --url https://data-stage.globalchange.gov \
    --file chapter_5_kf.json \
    --update

  Example input file (json format):

    {
        "chapter": 5,
        "process": "<p>This is a process.</p><p>This is a cite {{< tbib '6' '3ff0e30a-c5ee-4ed9-8034-288be428125b' >}} and emphasis: <em>Climate Science Special Report</em>.</p>",
        "kf": [
     {
         "identifier": "key-message-5-1",
         "ordinal": 1,
         "statement":  "<p>this is a statement</p>",
         "evidence": "<p>evidence with cites {{< tbib '37' 'd9661451-b35d-4e0c-9551-cbc60c45c5ef' >}}<sup class='cm'>,</sup>{{<tbib '38' 'd1069afd-d9c4-4cc1-bd29-c50f637502bd' >}}</p>", 
         "uncertainties": "<p>There is uncertainty </p>",
         "confidence": "<p>Increasing temperature is <em>highly likely</em> to result in early snowmelt and increased consumptive use.</p>"
     },
     {
         "identifier": "key-message-5-2",
         "ordinal": 2,
         "statement":  "<p>this is another statement</p>",
         "evidence": "<p>evidence with cites {{< tbib '37' 'd9661451-b35d-4e0c-9551-cbc60c45c5ef' >}}<sup class='cm'>,</sup>{{<tbib '38' 'd1069afd-d9c4-4cc1-bd29-c50f637502bd' >}}</p>", 
         "uncertainties": "<p>There is uncertainty </p>",
         "confidence": "<p>Increasing temperature is <em>highly likely</em> to result in early snowmelt and increased consumptive use.</p>"
     }
        ]
    }

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
  'report=s'    => \(my $report),
  'update'   => \(my $update),
  'verbose'   => \(my $verbose),
  'very_verbose' => \(my $very_verbose),
  'dry_run|n' => \(my $dry_run),
  'help|?'    => sub { pod2usage(verbose => 2) },
) or die pod2usage(verbose => 1);

pod2usage(msg => "missing url", verbose => 1) unless $url;
pod2usage(msg => "missing file", verbose => 1) unless $file;
pod2usage(msg => "missing report", verbose => 1) unless $report;


&main;

sub main {

    say "Add Findings to GCIS";
    say " url : $url";
    say " file : $file";
    say " update existing on" if $update;
    say " verbose on" if $verbose;
    say " very verbose on" if $very_verbose;
    say " dry run" if $dry_run;

    $verbose = 1 if $very_verbose;

    my $gcis = $dry_run ? Gcis::Client->new(url => $url) :
                       Gcis::Client->connect(url => $url);

    my $findings = load_data($file);
    my $chapter_num = $findings->{chapter};
    my $gcis_chapter = $gcis->get("/report/$report/chapter/$chapter_num");
    unless ( $gcis_chapter ) {
        say " Chapter $chapter_num does not exist";
        exit;
    }
    my $chapter = $gcis_chapter->{identifier};

    say " chapter: $chapter";
    my $process = $findings->{process};
    foreach my $finding (@{ $findings->{kf} }) {
        say "---";
        say " finding: $finding->{identifier}";
        # Pull GCIS finding
        my $finding_uri = "/report/$report/chapter/$chapter/finding";
        say " checking: $finding_uri/$finding->{identifier}";
        my $gcis_finding = $gcis->get("$finding_uri/$finding->{identifier}");
        if ( ! $gcis_finding ) {
            say " New finding to GCIS" if $verbose;
        }
        else {
            say " Existing finding to GCIS" if $verbose;
            say " gcis finding :\n".Dumper($gcis_finding) if $very_verbose;
            unless ( $update ) {
                say "   Not updating existing finding";
                next;
            }
            say "   Updating existing finding";
            $finding_uri = "/report/$report/chapter/$chapter/finding/$finding->{identifier}";
        }
        my $finding_postdata = build_finding($finding, $process, $report, $chapter);
        post_finding($finding_uri, $gcis, $finding_postdata);
    }
    say "done";
}

sub load_data {
    my $file = shift;

    #open my $f, '<:encoding(UTF-8)', $file or die "can't open file : $file";
    open my $f, '<', $file or die "can't open file : $file";

    my $json = do { local $/; <$f> };
    my $key_findings = decode_json($json);

    return $key_findings;
}

sub build_finding {
    my ($finding, $process, $report, $chapter) = @_;

    my $post_data = {
        identifier            => $finding->{identifier},
        report_identifier     => $report,
        chapter_identifier    => $chapter,
        confidence            => $finding->{confidence},
        evidence              => $finding->{evidence},
        ordinal               => $finding->{ordinal},
        statement             => $finding->{statement},
        uncertainties         => $finding->{uncertainties},
        process               => $process,

    };

    return $post_data;
}


sub post_finding {
    my ($uri, $gcis, $finding_postdata) = @_;

    say " finding to post :\n".Dumper($finding_postdata) if $very_verbose;

    if ($dry_run) {
        say "DRYRUN: would post finding to : $finding_postdata->{identifier}";
        return 0;
    }

    say " Posting finding for : $uri";
    $gcis->post($uri, $finding_postdata) or 
        warn " unable to post finding for : $finding_postdata->{identifier}";

    return 1;
}
