#!/usr/bin/env perl

=head1 NAME

    connect_findings_to_references.pl -- Ensure references associated with findings match tbib tags.

=head1 OPTIONS

=head2 B<--url>

    GCIS url, e.g. http://data-stage.globalchange.gov

=head2 B<--report>

    report, e.g. nca3

=head2 B<--chapter_number>

    Chapter number. Optional

=head2 B<--dry_run>, B<n>

    Dry run.

=head1 EXAMPLES

    connect_findings_to_references.pl -u http://localhost:3000 -r nca3 -c 5

=cut

use Getopt::Long qw/GetOptions/;
use Data::Dumper;
use Encode;
use Pod::Usage;
no warnings 'uninitialized';

use Gcis::Client;

use v5.14;

GetOptions(
  'url=s'            => \(my $url),
  'report=s'         => \(my $report),
  'chapter_number=s' => \(my $chapter_number),
  'dry_run|n'        => \(my $dry_run),
  'help'             => sub { pod2usage(verbose => 1 ) },
) or die pod2usage("invalid options.");

die "missing url" unless $url;
die "missing report" unless $report;

my $c = Gcis::Client->new;

$c->url($url);
$c->find_credentials->login;

my @findings;
if ( $chapter_number ) {
    @findings = $c->findings(report => $report, chapter_number => $chapter_number);
} else {
    @findings = $c->findings(report => $report);
}

my @fields = qw/statement uncertainties evidence confidence process/;

for my $f (@findings) {
    my $finding_uri = $f->{uri} or die "missing uri";
    my $finding = $c->get_form($f);

    #say "Finding:" . Dumper $f;
    #say "Finding form:" . Dumper $finding;
    my @uuids;
    say "finding $finding->{identifier}";
    for my $field (@fields) {
        local $_ = $finding->{$field} or next;
        push @uuids, $_ =~ m[<tbib>([a-z0-9-]+)</tbib>]g;
    }

    #say "UUIDs:" . Dumper \@uuids;

    my $finding_with_refs = $c->get($finding_uri);
    #say "Finding with refs" . Dumper $finding_with_refs;
    my %extra = map {
        # /reference/uuid => 1
        $_->{uri} => 1
    } @{ $finding_with_refs->{references} };
    #say "Initial Extras: " . Dumper \%extra;

    say "# uuids in text : ".@uuids;
    # Associate references with this finding.
    for my $refid (@uuids) {
        delete $extra{"/reference/$refid"};
        my $ref = $c->get("/reference/$refid");
        ##say "Ref for $refid: " . Dumper $ref;
        if (grep { $finding_uri eq $_ } @{ $ref->{publications} } ){
            say "already connected to $refid";
        }
        elsif ($dry_run) {
            say "ready to post to /reference/rel/$refid";
        } else {
            say "$finding_uri -> /reference/$refid";
            $c->post("/reference/rel/$refid.json", { add_subpubref_uri => $finding_uri }) or warn $c->error;
        }
    }
    #say "Final Extras: " . Dumper \%extra;

    for my $extra (keys %extra) {
        say "extra : $extra";
        my $uri = $extra;
        $uri =~ s[reference/][reference/rel/];
        if ($dry_run) {
            say "ready to post to $uri to remove $finding_uri";
        } else {
            $c->post("$uri.json", { delete_subpub => $finding_uri }) or warn $c->error;
        }
    }
}


