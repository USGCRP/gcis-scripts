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

=back

=head1 EXAMPLES

./find-authors-from-orcid.pl --url "https://data.globalchange.gov" --doi doi-file.txt

=cut

use Gcis::Client;
use Data::Dumper;
use Mojo::Util qw/html_unescape/;
use Getopt::Long qw/GetOptions/;

use v5.16;

GetOptions(
  'url=s'      => \(my $url),
  'dois=s'     => \(my $doi_file),
) or die "bad opts";

die 'missing url' unless $url;
die 'missing doi file' unless $doi_file;
warn "url      : $url\n";
warn "doi file : $doi_file\n";

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
              last_name  => html_unescape($p->{'family-name'}{'value'}),
              first_name => html_unescape($p->{'given-names'}{'value'}),
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

my $articles = load_doi_file();

for my $doi ( @$articles ) {
    #print Dumper $article;
    #print "\n";
    my $data = get_orcid_authors($doi);
    print Dumper $data;
    #my $doi = $article->{doi} or next;
    #my $some = get_orcid_authors($doi);
}
