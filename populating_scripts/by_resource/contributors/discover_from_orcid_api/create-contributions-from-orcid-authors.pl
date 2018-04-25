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
use Time::Piece;

use v5.20;

binmode(STDOUT, ':encoding(utf8)');

GetOptions(
  'verbose'     => \(my $verbose = 0),
  'url=s'       => \(my $url),
  'input_csv=s' => \(my $input_file),
  'max_line=s'  => \(my $max = -1),
) or die "bad opts";

die 'missing url' unless $url;
die 'missing input CSV' unless $input_file;
warn "url       : $url\n";
warn "input CSV : $input_file\n";

my $gcis  = Gcis::Client->connect(url => $url);

# Read in the file, such that we have an array of intake hashes.
my $contributor_input_lines = intake_csv();

my $processed_rows = [];
my $row_process = {};
my $processed_n = 0;
for my $contributor_line ( @$contributor_input_lines ) {

    $processed_n++;
    if ( $max ne -1 && $processed_n > $max ) {
        say "Reached max $max processed rows! Done.";
        last;
    }

    if ( $verbose ) {
    say "------------------------------------------------------------------------------";
        say "DOI: $contributor_line->{'doi'}, OrcID: $contributor_line->{orcid}, Role: " . ($contributor_line->{contributor_role} // '' );
        if ( $contributor_line->{'Test Case'} ) {
            say "Test case $contributor_line->{'Test Case'}: Expected Result: $contributor_line->{'Expected Result'}:  ";
        }
        say "--------------------------------------------------------------";
    }

    $row_process = {
        doi             => $contributor_line->{doi},
        orcid           => $contributor_line->{orcid},
        contrib_role    => $contributor_line->{contributor_role} // "author",
        ignored         => '',
        skipping_contrib => '',
        person          => 'Not processed',
        org             => 'Not processed',
        contrib         => 'Not processed',
        contributor_needs_qa  => '',
        error           => '',
    };

    ## if `confirm_match` is Ignore - skip it
    if ( $contributor_line->{confirm_person_match} eq 'Ignore' ) {
        say "\tSkipping entry for DOI $contributor_line->{doi}, ORCiD: $contributor_line->{orcid}." if $verbose;
        $row_process->{ignored} = "TRUE";
        push @$processed_rows, $row_process;
        next;
    }

    ## Confirm basic fields
    my @required = qw/doi orcid/;
    my $failed;
    foreach my $req_field (@required) {
        unless ($contributor_line->{$req_field}) {
             say "\tLine missing required field $req_field";
             $row_process->{error} .= "Missing field $req_field. ";
             $failed = 1;
        }
    }
    if ( $failed ) {
        push @$processed_rows, $row_process;
        next;
    }

    # Check for conflicting person info. Update if required. Hand back the person.
    my $person = handle_person( $contributor_line );
    if (! $person ) {
        say "\tNo person could be established" if $verbose;
        push @$processed_rows, $row_process;
        next;
    }

    ### Always update the ORCid
    $person = update_orcid( $person, $contributor_line->{orcid} );
    if ( ! $person ) {
        push @$processed_rows, $row_process;
        next;
    }

    ## Org Handling
    my $org = handle_organization( $contributor_line );
    if ( ! $org ) {
        push @$processed_rows, $row_process;
        next;
    }
    elsif ( $org eq 'skip_contributor' ) {
        # We wanted to update the person, but organization & contributor are fine. Done with this line
        $row_process->{skipping_contrib} = "TRUE";
        push @$processed_rows, $row_process;
        say "\tShortcut out as requested." if $verbose;
        next;
    }

    my $contributor_id = handle_contributor(
        $person,
        $org,
        $contributor_line->{doi},
        $contributor_line->{contributor_role},
        $contributor_line->{sort_key},
    );

    if ( $contributor_id ) {
        say "\tContributor\tDOI $contributor_line->{doi}\tPerson $person->{id}\tOrg $org->{identifier}\tRole $contributor_line->{contributor_role} completed";
    }
    push @$processed_rows, $row_process;
}

dump_output();

## Functions

sub dump_output {
    my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
        or die "Cannot use CSV: ".Text::CSV->error_diag ();
    my $t = localtime;
    $t->time_separator('');
    $t->date_separator('');
    my $output = $t->date . "_" . $t->time . "_output.csv";
    open my $fh, ">:encoding(utf8)", "$output" or die "$output: $!";
    my @headers = qw/doi orcid contrib_role ignored skipping_contrib person org contrib contributor_needs_qa error/;
    $csv->say($fh, \@headers);
    foreach my $row ( @$processed_rows ) {
        my @printable;
        foreach my $key ( @headers ) {
            push @printable, $row->{$key};
        }
        $csv->say($fh, \@printable);
    }
    close $fh or die "output.csv: $!";
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
    if ( $contributor_line->{person_id} eq "N/A" ) {
        # Query by ORCID, just to doublecheck
        $gcis_person = $gcis->get("/person/$contributor_line->{orcid}");
        if ( $gcis_person  ) {
            say "\tExisting Person found via ORCID" if $verbose;
            $row_process->{person} = "Existed";
        } else {
            # Brand new person
            say "\tCreating new person" if $verbose;
            $gcis_person = create_person($contributor_line);
            if ( $gcis_person ) {
                $row_process->{person} = "Created";
            }
            else {
                say "\tCouldn't create Person" if $verbose;
                $row_process->{error} = "Couldn't create person";
                return;
            }
        }
    }
    else {
        $gcis_person = $gcis->get("/person/$contributor_line->{person_id}");
        if ( $gcis_person ) {
            say "\tExisting Person" if $verbose;
            $row_process->{person} = "Existed";
        }
        else {
            say "\tCouldn't retrieve Person" if $verbose;
            $row_process->{error} = "Couldn't retrieve person";
            return;
        }
    }

### ORCiD MisMatch
    my $orcid_mismatch = check_existing_orcid( $contributor_line, $gcis_person );
    if ( $orcid_mismatch ) {
        $row_process->{error} = "OrcID in GCIS $gcis_person->{orcid} mismatched";
        say "\tExisting ORCid Differs" if $verbose;
        return;
    }

### Update Name, URL as requested
    my $updates = 0;
    my $updated_person;
    if ( $contributor_line->{confirm_person_match} eq 'Update URL in GCIS' ) {
        say "\tUpdating person url" if $verbose;
        $updated_person->{url}         = $contributor_line->{person_url};
        $updated_person->{first_name}  = $gcis_person->{first_name};
        $updated_person->{last_name}   = $gcis_person->{last_name};
        $updated_person->{middle_name} = $gcis_person->{middle_name};
        $updated_person->{orcid}       = $gcis_person->{orcid};
        $updated_person->{id}          = $gcis_person->{id};
        $updates = 1;
    }
    if ( $contributor_line->{confirm_person_match} eq 'Update Name & URL in GCIS' ) {
        say "\tUpdating person url and name" if $verbose;
        $updated_person->{url}         = $contributor_line->{person_url};
        $updated_person->{first_name}  = $contributor_line->{first_name};
        $updated_person->{last_name}   = $contributor_line->{last_name};
        $updated_person->{middle_name} = $gcis_person->{middle_name};
        $updated_person->{orcid}       = $gcis_person->{orcid};
        $updated_person->{id}          = $gcis_person->{id};
        $updates = 1;
    }
    if ( $contributor_line->{confirm_person_match} eq 'Update Name in GCIS' ) {
        say "\tUpdating person name" if $verbose;
        $updated_person->{url}         = $gcis_person->{url};
        $updated_person->{first_name}  = $contributor_line->{first_name};
        $updated_person->{last_name}   = $contributor_line->{last_name};
        $updated_person->{middle_name} = $gcis_person->{middle_name};
        $updated_person->{orcid}       = $gcis_person->{orcid};
        $updated_person->{id}          = $gcis_person->{id};
        $updates = 1;
    }

    my $final_gcis_person = $gcis_person;
    if ( $updates ) {
        $final_gcis_person = $gcis->post("$gcis_person->{uri}", $updated_person);
        if ( $final_gcis_person ) {
            $row_process->{person} .= ". Updated Name and/or URL";
        }
        else {
            $row_process->{error} = "Person update failed";
            say "\tFailed updating" if $verbose;
            return;
        }
    }

    return $final_gcis_person;
## Complete Person Handling
}

sub create_person {
    my ($contributor_line) = @_;

    my $updates;
    $updates->{url}         = $contributor_line->{person_url} if $contributor_line->{person_url};
    $updates->{first_name}  = $contributor_line->{first_name};
    $updates->{last_name}   = $contributor_line->{last_name};
    $updates->{orcid}       = $contributor_line->{orcid};

    my $final_gcis_person = $gcis->post('/person',$updates);
    return $final_gcis_person;
}

sub check_existing_orcid {
    my ($contributor_line, $gcis_person) = @_;

    return 0 unless $gcis_person->{orcid};
    if ( $contributor_line->{orcid} ne $gcis_person->{orcid} ) {
        say "\tMismatch! Contrib: $contributor_line->{orcid}. Person: $gcis_person->{orcid}";
        return 1;
    }
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
    elsif ( $contributor_line->{organization_id} eq "" ) {
        # Query by name, just to doublecheck
        $gcis_organization = $gcis->post("/organization/lookup/name", { name => $contributor_line->{org_name}});
        if ( $gcis_organization ) {
            say "\tExisting Org found via name" if $verbose;
            $row_process->{org} = "Existed";
        } else {
            # Brand new org
            say "\tCreating new org" if $verbose;
            $gcis_organization = create_organization($contributor_line);
            if ($gcis_organization) {
                $row_process->{org} = "Created";
            }
            else {
                $row_process->{error} = "Org Creation Failed";
                return;
            }
        }
    }
    else {
        $gcis_organization = $gcis->get("/organization/$contributor_line->{organization_id}");
        if ($gcis_organization) {
            say "\tExisting GCIS Org" if $verbose;
            $row_process->{org} = "Existed";
        }
        else {
            $row_process->{error} = "Org Retrieval Failed";
            return;
        }
    }

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
    $updated_person->{id}          = $person->{id};
    $updated_person->{url}         = $person->{url};
    $updated_person->{first_name}  = $person->{first_name};
    $updated_person->{last_name}   = $person->{last_name};
    $updated_person->{middle_name} = $person->{middle_name};
    $updated_person->{orcid}       = $orcid;

    my $final_gcis_person = $gcis->post("/person/$person->{id}", $updated_person);
    if ( $final_gcis_person ) {
        say "\tUpdated orcid" if $verbose;
        $row_process->{person} .= ". Updated OrcID";
    }
    else {
        say "\tFailed updating orcid" if $verbose;
        $row_process->{error} = "Failed updating OrcID";
        return;
    }
    return $final_gcis_person;
}

sub handle_contributor {
    my ($person, $org, $doi, $role, $sort_key) = @_;

    $role = 'author' unless $role;

    # Does the contributor exist?
    my $contributions = $gcis->get("/person/$person->{id}/contributions/$role/article");
    for my $contribution ( @$contributions ) {
        if ($contribution->{doi} eq $doi) {
            say "\tContributor with this person and role already exists" if $verbose;
            $row_process->{contrib} = "Existed";
            $row_process->{contributor_needs_qa} = "TRUE";
            return 1;
        }
    }
    my $contributor_fields = {
        person_id               => $person->{id},
        organization_identifier => $org->{identifier},
        role                    => $role,
    };
    $contributor_fields->{sort_key} = $sort_key if defined $sort_key;

    my $result = $gcis->post("/article/contributors/$doi", $contributor_fields);

    if ( $result ) {
        $row_process->{contrib} = "Created";
        say "\tCreated Contributor" if $verbose;
    }
    else {
        $row_process->{error} = "Contributor create failed.";
        say "\tContributor creation failed for person $person->{id} org $org->{identifier} role <$role>" if $verbose;
        return;
    }

    return 1;
}

