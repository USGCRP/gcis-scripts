#!/usr/bin/env perl

=head1 NAME

find-authors-from-orcid.pl -- outputs authors from ORCiD based on DOIs

=head1 DESCRIPTION

TODO

=head1 SYNOPSIS

./find-authors-from-orcid.pl [OPTIONS]

=head1 OPTIONS

=over

=item B<--url>

The GCIS instance URL

=item B<--dois>

The file containing the DOIs to query

=item B<--csv>

The file to print the output to

=item B<--verbose>

Verbose output

=back

=head1 EXAMPLES

./find-authors-from-orcid.pl --url "https://data.globalchange.gov" --doi doi-file.txt --csv output.csv

=cut

use Gcis::Client;
use Data::Dumper;
use Mojo::Util qw/html_unescape/;
use Getopt::Long qw/GetOptions/;
use Text::CSV;
use Utils;

use v5.16;

GetOptions(
  'url=s'      => \(my $url),
  'dois=s'     => \(my $doi_file),
  'csv=s'      => \(my $csv_file),
  'verbose!'   => \(my $verbose),
) or die "bad opts";

die 'missing url' unless $url;
die 'missing doi file' unless $doi_file;
die 'missing csv file' unless $csv_file;
warn "url      : $url\n";
warn "doi file : $doi_file\n";
warn "csv file : $csv_file\n";

my $gcis  = Gcis::Client->connect(url => $url);
my $orcid = Gcis::Client->new->url("http://pub.orcid.org")->accept("application/orcid+json");

sub get_orcid_authors {
    my ($doi) = @_;
    my @authors;
    my $r = $orcid->get("/v1.2/search/orcid-bio/", { q => qq[digital-object-ids:"$doi"] });
    my $count = $r->{'orcid-search-results'}{'num-found'} or return \@authors;
    for (0..$count-1) {
        my $id = $orcid->tx->res->json("/orcid-search-results/orcid-search-result/$_/orcid-profile/orcid-identifier/path");
        my $p = $orcid->tx->res->json("/orcid-search-results/orcid-search-result/$_/orcid-profile/orcid-bio/personal-details");
        #my $q = $orcid->tx->res->json("/orcid-search-results/orcid-search-result/$_/orcid-profile");
        #print Dumper $q;
        push @authors, {
              last_name  => html_unescape($p->{'family-name'}{'value'} // ''),
              first_name => html_unescape($p->{'given-names'}{'value'} // ''),
              orcid      => $id,
              doi        => $doi,
        };
    }
    #print "DOI: $doi. ORCiDS:";
    #print Dumper \@authors;
    return \@authors; 
}

#sub find_or_create_gcis_person($person) {
#    my $match;
#
#    # ORCID
#    if ($person->{orcid} and $match = $gcis->get("/person/$person->{orcid}")) {
#        debug "Found orcid: $person->{orcid}";
#        return $match;
#    }
#
#    # Match first + last name
#    if ($match = $gcis->post_quiet("/person/lookup/name",
#            { last_name => $person->{last_name},
#              first_name => $person->{first_name}
#          })) {
#        if ($match->{id}) {
#            return $match;
#        }
#    }
#
#    # Add more heuristics here
#
#    return if $dry_run;
#
#    unless ($person->{first_name}) {
#        debug "no first name ".Dumper($person);
#        return;
#    }
#
#    unless ($person->{last_name}) {
#        debug "no last name ".Dumper($person);
#        return;
#    }
#
#    debug "adding new person $person->{first_name} $person->{last_name}";
#    my $new = $gcis->post("/person" => {
#            first_name => $person->{first_name},
#             last_name => $person->{last_name},
#                 orcid => $person->{orcid}
#            }) or do {
#            warn "Error creating ".Dumper($person)." : ".$gcis->error;
#            return;
#        };
#
#    return $new;
#}

sub load_doi_file {
    open my $f, '<:encoding(UTF-8)', $doi_file or die "can't open file : $doi_file";
    chomp(my @article_dois = <$f>);
    close $f;

    return \@article_dois
}

sub print_to_CSV {
    my ($data) = @_;

    my @data_for_print = ();

    my @keys = keys %{ $data->[0] };

    push @keys, "confirm_match";
    push @keys, "organization_id";
    push @keys, "person_url";
    push @keys, "org_name";
    push @keys, "org_type";
    push @keys, "org_url";
    push @keys, "org_country_code";
    push @keys, "org_international_flag";

    #print Dumper \@keys;
    push @data_for_print, \@keys;

    for my $person ( @{$data} ) {
        my @row;
        push @row, $person->{$_} foreach @keys;
        push @data_for_print, \@row;
    }

    #print Dumper \@data_for_print;
    my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
                    or die "Cannot use CSV: ".Text::CSV->error_diag ();
    $csv->eol ("\r\n");
    open my $fh, ">:encoding(utf8)", $csv_file or die "new.csv: $!";
    $csv->print ($fh, $_) for @data_for_print;
    close $fh or die "new.csv: $!";

    return;
}

sub get_person {
    my ($entry) = @_;

    # Query GCIS Search:
    # # ORCid
    # GET "/person/[ORCID]"
    my $clean_orcid = Utils::url_escape($entry->{orcid});

    print "Searching for person with $clean_orcid\n" if $verbose;
    my $person = $gcis->get("/person/$clean_orcid");
    if ( $person ) {
        print "\tFound person $person->{id} via $clean_orcid\n" if $verbose;
        return ($person, "ORCiD Matched");
    }
    # # First + Last
    # GET "/person/[FIRST]-[LAST]"
    my $clean_name = Utils::url_escape($entry->{first_name}) . "_" . Utils::url_escape($entry->{last_name});
    print "Searching for person with $clean_name\n" if $verbose;
    my $person = $gcis->get("/person/$clean_name");
    if ( $person ) {
        print "Found person $person->{id} via $clean_name\n" if $verbose;
        return ($person, "Full Name Matched");
    }

    print "No person found\n" if $verbose;
    return (undef, "No Match");
}

my $articles = load_doi_file();

say "Processing " . @$articles . " DOIs.\nShould take about " . 0.15 * @$articles / 60 . " minutes to run this first process.";

my $orcid_data;
say "Pulling data from DOI";
for my $doi ( @$articles ) {
    #print Dumper $article;
    #print "\n";
    my $data = get_orcid_authors($doi);
    foreach my $author ( @{$data} ) {
        push @$orcid_data, $author;
    }
    #print Dumper $orcid_data;
    #my $doi = $article->{doi} or next;
    #my $some = get_orcid_authors($doi);
}
say "";

say "Found " . @$orcid_data . " ORCiD entries to check against GCIS.\nShould take about " . 0.15 * @$orcid_data / 60 . " minutes to run this last process.";
my $all_data;
for my $entry ( @$orcid_data ) {

    my ($person, $match_method) = get_person($entry);

    if ( $person ) {
        print "Adding person to entry: $person->{id} matched via $match_method\n" if $verbose;
        $entry->{person_id} = $person->{id};
        $entry->{match_method} = $match_method;
    }
    else {
        $entry->{person_id} = '';
        $entry->{match_method} = '';
    }
    #print Dumper $entry;
    push @$all_data, $entry;

    # Person_ID - the Person id returned from the GCIS matching
    # Match Method - "ORCiD Match", "Full Name Match", "Last Name Match", "No Match", ...
}

print_to_CSV($all_data);
