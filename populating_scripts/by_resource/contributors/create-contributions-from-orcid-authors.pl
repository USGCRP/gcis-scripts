#!/usr/bin/env perl

=head1 NAME

create-contributions-from-orcid-authors.pl -- 

=head1 DESCRIPTION


=head1 SYNOPSIS

./create-contributions-from-orcid-authors.pl [OPTIONS]

=head1 OPTIONS

=over

=item B<--url>

The GCIS instance URL

=item B<--input_csv>

The QA'd csv file initially output from find-authors-by-orcid.pl

=item B<--dry_run> or B<--n>

Dry run, no changes to GCIS.

=item B<--verbose>

Chatter through the process

=back

=head1 EXAMPLES

./create-contributions-from-orcid-authors.pl --url "https://data-stage.globalchange.gov" --input foo.csv

=cut

use Gcis::Client;
use Data::Dumper;
use YAML::XS qw/Dump/;
use Mojo::Util qw/html_unescape/;
use Getopt::Long qw/GetOptions/;
use Text::CSV;

use v5.20;

binmode(STDOUT, ':encoding(utf8)');

GetOptions(
  'dry_run|n'   => \(my $dry_run = 0),
  'verbose'     => \(my $verbose = 0),
  'url=s'       => \(my $url),
  'input_csv=s' => \(my $input_file),
) or die "bad opts";

die 'missing url' unless $url;
die 'missing input CSV' unless $input_file;
warn "DRY RUN\n" if $dry_run;
warn "url       : $url\n";
warn "input CSV : $input_file\n";

my $gcis  = Gcis::Client->connect(url => $url);
my $seen_orcids = {};

sub debug($) {
    warn "# @_\n";
}

sub intake_csv {
    my @rows;
    my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
                    or die "Cannot use CSV: ".Text::CSV->error_diag ();
    open my $fh, "<:encoding(utf8)", $input_file or die "$input_file: $!";
    while ( my $row = $csv->getline( $fh ) ) {
        push @rows, $row;
    }
    $csv->eof or $csv->error_diag();
    close $fh;

    my $columns = shift @rows;
    say "Found Columns: " . join(", ", @$columns) if $verbose;
    my @input_lines;
    for my $row ( @rows ) {
        my %entry;
        my $index = 0;
        for my $col ( @$columns ) {
            $entry{$col} = $row->[$index];
            $index++;
        }
        push @input_lines, \%entry;
    }
    #say Dumper \@input_lines;
    return \@input_lines;
}

# Read in the file, such that we have an array of intake hashes.
my $contributor_input_lines = intake_csv();

my $handled;
for my $contributor_line ( @$contributor_input_lines ) {

## if `confirm_match` is Ignore - skip it
    if ( $contributor_line->{confirm_match} eq 'Ignore' ) {
        say "Skipping entry for DOI $contributor_line->{doi}, ORCiD: $contributor_line->{orcid}." if $verbose;
        next;
    }

    my $person_id = handle_person( $contributor_line );

    my $org_id = handle_organization( $contributor_line );
## Org Handling
### If there is no `organization_id` - create an org with the
#    "org_name org_type org_url org_country_code org_international_flag related_org related_org_relationship"
### If tehre is an organization_id - we're good
## Complete Org Handling

    update_orcid( $contributor_line );
### Always update the ORCid

    my $contributor_id = handle_contributor( $person_id, $org_id, $contributor_line->{doi}, $contributor_line->{contributor_role} );
## Contributor Handling
### Must be a contributor role
### If the Person + Org + Role already exists on this Article - done
### Otherwise, create Contributor
## Complete Contributor section

    my $msg = "Created Contributor\tDOI $contributor_line->{doi}\tPerson $person_id\tOrg $org_id\tRole $contributor_line->{contributor_role}";
    say $msg if $verbose;
    push @$handled, $msg;
}

dump_output($handled);

sub handle_person {
    my ($contributor_line) = @_;

    # New person
    ## No assigned person id and No seen ORCid (created from an earlier line)
    my $gcis_person;
    if ( $contributor_line->{person_id} eq "N/A" && ! exists $seen_orcids->{ $contributor_line->{orcid} }) {
       $gcis_person = create_person($contributor_line);
    }
    elsif ( $contributor_line->{person_id} ne "N/A") {
        $gcis_person = $gcis->get("/person/$contributor_line->{person_id}");
    }
    else {
        $gcis_person = $gcis->get("/person/$contributor_line->{orcid}");
    }

### ORCiD MisMatch
    my $orcid_mismatch = check_existing_orcid( $contributor_line );
    if ( $orcid_mismatch ) {
        my $msg = "Existing ORCid Differs\tDOI $contributor_line->{doi}\tPerson ORCid $orcid_mismatch\tSheet ORCid $contributor_line->{orcid}";
        say $msg if $verbose;
        push @$handled, $msg;
        return;
    }

### Update Name, URL as requested
    my $update_name, $update_url;
    if ( $contributor_line->{confirm_match} eq 'Update URL in GCIS' ) {
        $update_url = 1;
        # add new url to update hash
    }
    elsif ( $contributor_line->{confirm_match} eq 'Update Name & URL in GCIS' ) {
        # add new url to update hash
        # add new name to update hash
        $update_url = 1;
        $update_name = 1;
    }
    elsif ( $contributor_line->{confirm_match} eq 'Update Name in GCIS' ) {
        $update_name = 1;
        # add new name to update hash
    }

    # if update hash has values, send update


    $seen_orcids->{ $contributor_line->{orcid} } = 1;
## Complete Person Handling
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

#sub add_contributor_record($person,$article,$sort_key) {
#    warn "dry run" if $dry_run;
#    return if $dry_run;
#
#    my $uri = $article->{uri};
#    $uri =~ s[article][article/contributors];
#    $gcis->post( $uri => {
#            person_id => $person->{id},
#            role => 'author',
#            sort_key => $sort_key,
#        }) or debug "error posting to $uri: ".$gcis->error;
#}


# for my $article ($gcis->get("/article", { all => $all })) {    ### Getting--->   done
#     my $doi = $article->{doi} or next;
#     my $some = get_orcid_authors($doi);
#     my $all = get_xref_authors($doi) or die "no authors for $doi";
#     my $merged = combine_author_list($some,$all) or next;
#     if ($dump) {
#         printf "%100s\n",$doi;
#         for (@$merged) {
#             printf "%-25s %-30s %-30s\n",$_->{orcid},$_->{first_name},$_->{last_name};
#         }
#         next;
#     }
#     my $i = 10;
#     for my $person (@$merged) {
#         my $found = find_or_create_gcis_person($person);
#         next unless $found;
#         add_contributor_record($found, $article, $i);
#         $i += 10;
#     }
# }


