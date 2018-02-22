#!/usr/bin/env perl

=head1 NAME

create-contributions-from-orcid-authors.pl -- create contributors from OrcID DOIs

=head1 DESCRIPTION

This script takes the curated output CSV from the script qa_scripts/find-authors-from-orcid.pl
and creates the Contributors. Will create persons and orgs if needed.

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
my $seen_entities = {};

# Read in the file, such that we have an array of intake hashes.
my $contributor_input_lines = intake_csv();

my $handled;
for my $contributor_line ( @$contributor_input_lines ) {

    ## if `confirm_match` is Ignore - skip it
    if ( $contributor_line->{confirm_match} eq 'Ignore' ) {
        say "Skipping entry for DOI $contributor_line->{doi}, ORCiD: $contributor_line->{orcid}." if $verbose;
        next;
    }

    # Check for conflicting person info. Update if required. Hand back the person.
    my $person = handle_person( $contributor_line );
    next unless $person;

    ### Always update the ORCid
    update_orcid( $person, $contributor_line->{orcid} );

    ## Org Handling
    my $org = handle_organization( $contributor_line );
    if ( $org eq 'skip_contributor' ) {
        # We wanted to update the person, but organization & contributor are fine. Done with this line
        my $msg = "Updated Person $person->{id}, shortcut out of Organization & Contributor updating.";
        say $msg if $verbose;
        push @$handled, $msg;
        next;
    }

    my $contributor_id = handle_contributor(
        $person,
        $org,
        $contributor_line->{doi},
        $contributor_line->{contributor_role},
        $contributor_line->{sort_key},
    );

    my $msg = "Created Contributor\tDOI $contributor_line->{doi}\tPerson $person->{id}\tOrg $org->{identifier}\tRole $contributor_line->{contributor_role}";
    say $msg if $verbose;
    push @$handled, $msg;
}

dump_output($handled);

## Functions

sub dump_output {
    return 1;
}

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


sub handle_person {
    my ($contributor_line) = @_;

    # New person
    ## No assigned person id and No seen ORCid (created from an earlier line)
    my $gcis_person;
    if ( $contributor_line->{person_id} eq "N/A" && ! exists $seen_entities->{ $contributor_line->{orcid} }) {
        # Brand new person
       $gcis_person = create_person($contributor_line);
    }
    elsif ( $contributor_line->{person_id} ne "N/A") {
        # Existing person in GCIS
        $gcis_person = $gcis->get("/person/$contributor_line->{person_id}");
    }
    else {
        # Person ID not provided, but we created this person earlier in the script
        $gcis_person = $gcis->get("/person/$seen_entities->{$contributor_line->{orcid}}");
    }

### ORCiD MisMatch
    my $orcid_mismatch = check_existing_orcid( $contributor_line, $gcis_person );
    if ( $orcid_mismatch ) {
        my $msg = "Existing ORCid Differs\tDOI $contributor_line->{doi}\tPerson ORCid $gcis_person->{orcid}\tSheet ORCid $contributor_line->{orcid}";
        say $msg if $verbose;
        push @$handled, $msg;
        return;
    }

### Update Name, URL as requested
    my $updates = 0;
    my $updated_person;
    if ( $contributor_line->{confirm_match} eq 'Update URL in GCIS' ) {
        $updated_person->{url}         = $contributor_line->{url};
        $updated_person->{first_name}  = $gcis_person->{first_name};
        $updated_person->{last_name}   = $gcis_person->{last_name};
        $updated_person->{middle_name} = $gcis_person->{middle_name};
        $updated_person->{orcid}       = $gcis_person->{orcid};
        $updates = 1;
    }
    if ( $contributor_line->{confirm_match} eq 'Update Name & URL in GCIS' ) {
        $updated_person->{url}         = $contributor_line->{url};
        $updated_person->{first_name}  = $contributor_line->{first_name};
        $updated_person->{last_name}   = $contributor_line->{last_name};
        $updated_person->{middle_name} = $gcis_person->{middle_name};
        $updated_person->{orcid}       = $gcis_person->{orcid};
    }
    if ( $contributor_line->{confirm_match} eq 'Update Name in GCIS' ) {
        $updated_person->{url}         = $gcis_person->{url};
        $updated_person->{first_name}  = $contributor_line->{first_name};
        $updated_person->{last_name}   = $contributor_line->{last_name};
        $updated_person->{middle_name} = $gcis_person->{middle_name};
        $updated_person->{orcid}       = $gcis_person->{orcid};
        $updates = 1;
    }

    my $final_gcis_person = $gcis_person;
    if ( $updates ) {
        $final_gcis_person = $gcis->post($gcis_person->{uri}, $updated_person)
    }

    $seen_entities->{ $contributor_line->{orcid} } = 1;
    return $final_gcis_person;
## Complete Person Handling
}

sub create_person {
    my ($contributor_line) = @_;
    my $updates;
    $updates->{url}         = $contributor_line->{url} if $contributor_line->{url};
    $updates->{first_name}  = $contributor_line->{first_name};
    $updates->{last_name}   = $contributor_line->{last_name};
    $updates->{orcid}       = $contributor_line->{orcid};

    my $final_gcis_person = $gcis->post('/person',$updates);
    return $final_gcis_person;
}

sub check_existing_orcid {
    my ($contributor_line, $gcis_person) = @_;

    return 1 if ( $contributor_line->{orcid} ne $gcis_person->{orcid} );
    return;
}

sub handle_organization {
    my ($contributor_line) = @_;

    my $gcis_organization;
    # Shortcut out, we're done
    if ( $contributor_line->{organization_id} eq "skip_contributor") {
        return 'skip_contributor';
    }
    # New Organization
    ## No assigned org id and No seen org_name (created from an earlier line)
    elsif ( $contributor_line->{organization_id} eq "" && ! exists $seen_entities->{ $contributor_line->{org_name} }) {
        # Brand new org
        #  "org_name org_type org_url org_country_code org_international_flag related_org related_org_relationship"
       $gcis_organization = create_organization($contributor_line);
    }
    elsif ( $contributor_line->{person_id} ne "N/A") {
        # Existing org in GCIS
        $gcis_organization = $gcis->get("/organization/$contributor_line->{organization_id}");
    }
    else {
        # Person ID not provided, but we created this person earlier in the script
        $gcis_organization = $gcis->get("/organization/$seen_entities->{$contributor_line->{org_name}}");
    }

    $seen_entities->{ $contributor_line->{org_name} } = 1;
    return $gcis_organization;
## Complete Org Handling
}

sub create_organization {
    my ($contributor_line) = @_;
    my $updates;
    $updates->{name}                         = $contributor_line->{org_name};
    $updates->{url}                          = $contributor_line->{org_url} if $contributor_line->{org_url};
    $updates->{country_code}                 = $contributor_line->{org_country_code};
    $updates->{organization_type_identifier} = $contributor_line->{org_type};
    $updates->{international}                = $contributor_line->{org_international_flag} if $contributor_line->{org_international_flag};

    my $final_gcis_org = $gcis->post('/organization', $updates);
    return $final_gcis_org;
}


sub update_orcid {
    my ( $person, $orcid ) = @_;

    my $updated_person;
    $updated_person->{url}         = $person->{url};
    $updated_person->{first_name}  = $person->{first_name};
    $updated_person->{last_name}   = $person->{last_name};
    $updated_person->{middle_name} = $person->{middle_name};
    $updated_person->{orcid}       = $orcid;

    my $final_gcis_person = $gcis->post($person->{uri}, $updated_person);
    return $final_gcis_person;
}

sub handle_contributor {
    my ($person, $org, $doi, $role, $sort_key) = @_;

    return unless $role;

    # Does the contributor exist?
    my $contributions = $gcis->get("/person/$person->{id}/contributions/$role/article");
    for my $contribution ( @$contributions ) {
        return 1 if $contribution->{doi} eq $doi;
    }
    my $contributor_fields = {
        person_id               => $person->{id},
        organization_identifier => $org->{identifier},
        role                    => $role,
    };
    $contributor_fields->{sort_key} = $sort_key if defined $sort_key;

    my $result = $gcis->post("/article/contributors/$doi/", $contributor_fields);

    return 1;
}

