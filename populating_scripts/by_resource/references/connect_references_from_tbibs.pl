#!/usr/bin/env perl

=head1 NAME

    connect_references_from_tbibs.pl -- Ensure references associated with findings match tbib tags.

=head1 OPTIONS

=head2 B<--url>

    GCIS url, e.g. http://data-stage.globalchange.gov

=head2 B<--report>

    report, e.g. nca3

=head2 B<--chapter_number>

    Chapter number. Optional

=head2 B<--resource>

    Which resource to search for tbibs & connect references to.

    Valid options:
      finding (searches : statement, uncertainties, evidence, confidence, process)
      figure  (searches : caption)

=head2 B<--remove_references>

    Boolean. Will remove any references not found in the text from a resource.

=head2 B<--dry_run>, B<n>

    Dry run.

=head1 EXAMPLES

    connect_references_from_tbibs.pl -u http://localhost:3000 --report nca3 -c 5 --resource finding

=cut

use Getopt::Long qw/GetOptions/;
use Data::Dumper;
use Encode;
use Pod::Usage;

use Gcis::Client;

use v5.14;

GetOptions(
  'url=s'             => \(my $url),
  'report=s'          => \(my $report),
  'chapter_number=s'  => \(my $chapter_number),
  'resource=s'        => \(my $resource_type),
  'dry_run|n'         => \(my $dry_run),
  'remove_references' => \(my $remove_refs),
  'help'              => sub { pod2usage(verbose => 1 ) },
) or die pod2usage("invalid options.");

die "missing url" unless $url;
die "missing report" unless $report;
die "missing resource" unless $resource_type;
die "invalid resource" unless ( $resource_type eq 'figure' || $resource_type eq 'finding' );

my $c = Gcis::Client->new;

$c->url($url);
$c->find_credentials->login;

my @resources = get_resources();

my $fields = {
    finding => [
        "statement",
        "uncertainties",
        "evidence",
        "confidence",
        "process"
    ],
    figure  => [
        "caption",
    ],
};

for my $r (@resources) {
    my $resource_uri = $r->{uri} or die "missing uri";
    my $resource = $c->get_form($r);

    #say "Resource" . Dumper $r;
    #say "Resource ($resource) form:" . Dumper $resource;
    my @uuids;
    #say "resource ($resource_type) $resource->{identifier}";
    for my $field (@{ $fields->{$resource_type} }) {
        my $field_value = $resource->{$field};
        next unless $field_value;
        #say "Analyzing $resource_uri field $field: $field_value";
        push @uuids, $field_value =~ m[<tbib> *([a-z0-9-]+) *</tbib>]g;
    }

    #say "UUIDs:" . Dumper \@uuids;

    my $resource_with_refs = $c->get($resource_uri);
    #say "resource with refs" . Dumper $resource_with_refs;
    my %extraneous = map {
        # /reference/uuid => 1
        $_->{uri} => 1
    } @{ $resource_with_refs->{references} };
    #say "Initial Extras: " . Dumper \%extraneous;

    say "# uuids in text : ".@uuids;
    # Associate references with this resource.
    for my $refid (@uuids) {
        delete $extraneous{"/reference/$refid"};
        my $ref = $c->get("/reference/$refid");
        ##say "Ref for $refid: " . Dumper $ref;
        if (grep { $resource_uri eq $_ } @{ $ref->{publications} } ){
            say "already connected to $refid";
        }
        elsif ($dry_run) {
            say "ready to post to /reference/rel/$refid";
        } else {
            say "$resource_uri -> /reference/$refid";
            $c->post("/reference/rel/$refid.json", { add_publication_uri => $resource_uri }) or warn $c->error;
        }
    }
    #say "Final Extras: " . Dumper \%extraneous;

    for my $extraneous (keys %extraneous) {
        unless ( $remove_refs ) {
            say "Not removing extraneous reference $extraneous";
            next;
        }
        say "extraneous reference to remove: $extraneous";
        my $uri = $extraneous;
        $uri =~ s[reference/][reference/rel/];
        if ($dry_run) {
            say "ready to post to $uri to remove $resource_uri";
        } else {
            $c->post("$uri.json", { delete_publication => $resource_uri }) or warn $c->error;
        }
    }
}


sub get_resources {
    if ( $resource_type eq "finding" ) {
        if ( $chapter_number ) {
            return $c->findings(report => $report, chapter_number => $chapter_number);
        } else {
            return $c->findings(report => $report);
        }
    }
    elsif ( $resource_type eq "figure" ) {
        if ( $chapter_number ) {
            return $c->figures(report => $report, chapter_number => $chapter_number);
        } else {
            return $c->figures(report => $report);
        }
    }
    return;
}
