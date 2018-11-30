#!/usr/bin/env perl

=head1 NAME

bulk-create-contributors.pl -- create contributors from input CSV

=head1 DESCRIPTION


=head1 SYNOPSIS

./bulk-create-contributors.pl [OPTIONS]

=head1 OPTIONS

=over

=item B<--url>

The GCIS instance URL

=item B<--input_csv>

The QA'd csv file initially output from find-authors-by-orcid.pl

=item B<--max_lines>

Only process so many rows

=item B<--output>

Output QA file. Defaults to [DATE]_[TIME]_output.csv.

=item B<--dryrun>

Don't actually add them

=item B<--verbose>

Chatter through the process

=back

=head1 EXAMPLES

./bulk-create-contributors.pl --url "https://data-stage.globalchange.gov" --input foo.csv

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
  'dry'         => \(my $dry = 0),
  'url=s'       => \(my $url),
  'input_csv=s' => \(my $input_file),
  'max_line=s'  => \(my $max = -1),
  'output=s'  => \(my $output_file = -1),
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
        say "DOI: $contributor_line->{'doi'}, Person: $contributor_line->{'person_id'}, Org: $contributor_line->{'organization_id'}, Role: $contributor_line->{contributor_role}, Sort Key: $contributor_line->{'sort_key'}";
        say "--------------------------------------------------------------";
    }

    $row_process = {
        doi                 => $contributor_line->{doi},
        contributor_role    => $contributor_line->{contributor_role},
        person_id           => $contributor_line->{person_id},
        organization_id     => $contributor_line->{organization_id},
        sort_key            => $contributor_line->{sort_key},'',
        contributor         => 'Not processed',
        contributor_existed => '',
        error               => '',
    };

    ## Confirm basic fields
    my @required = qw/doi person_id organization_id contributor_role sort_key/;
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
    my $person = get_person( $contributor_line );
    if (! $person ) {
        push @$processed_rows, $row_process;
        next;
    }

    ## Org Handling
    my $org = get_organization( $contributor_line );
    if ( ! $org ) {
        push @$processed_rows, $row_process;
        next;
    }

    my $contributor_created = create_contributor(
        $person,
        $org,
        $contributor_line->{doi},
        $contributor_line->{contributor_role},
        $contributor_line->{sort_key},
    );

    if ( $contributor_created ) {
        print "DRYRUN: " if $dry;
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
    my $output = $output_file ? $output_file : $t->date . "_" . $t->time . "_output.csv";
    open my $fh, ">:encoding(utf8)", "$output" or die "$output: $!";
    my @headers = qw/doi contributor_role person_id organization_id sort_key contributor contributor_existed error/;

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


sub get_person {
    my ($contributor_line) = @_;

    # New person
    ## No assigned person id and No seen ORCid (created from an earlier line)
    my $gcis_person = $gcis->get("/person/$contributor_line->{person_id}");
    if ( $gcis_person ) {
        say "\tPerson found" if $verbose;
    }
    else {
        say "\tCouldn't retrieve Person" if $verbose;
        $row_process->{error} = "Couldn't retrieve person";
        return;
    }
    return $gcis_person;
}

sub get_organization {
    my ($contributor_line) = @_;

    my $gcis_organization = $gcis->get("/organization/$contributor_line->{organization_id}");
    if ( $gcis_organization ) {
        say "\tOrg found" if $verbose;
    }
    else {
        say "\tCouldn't retrieve Organization" if $verbose;
        $row_process->{error} = "Org Retrieval Failed";
        return;
    }

    return $gcis_organization;
}

sub create_contributor {
    my ($person, $org, $doi, $role, $sort_key) = @_;

    # Does the contributor exist?
    my $contributions = $gcis->get("/person/$person->{id}/contributions/$role/article");
    for my $contribution ( @$contributions ) {
        if ($contribution->{doi} eq $doi) {
            say "\tContributor with this person and role already exists" if $verbose;
            $row_process->{contributor_existed} = "TRUE";
            return 1;
        }
    }
    my $contributor_fields = {
        person_id               => $person->{id},
        organization_identifier => $org->{identifier},
        role                    => $role,
    };
    $contributor_fields->{sort_key} = $sort_key if defined $sort_key;


    if ( $dry ) {
        $row_process->{contributor} = "DRYRUN: Would Have Created";
        say "\tDRYRUN: Would Have Created Contributor" if $verbose;
        $row_process->{contributor_existed} = "FALSE";
        return 1;
    }

    my $result = $gcis->post("/article/contributors/$doi", $contributor_fields);

    if ( $result ) {
        $row_process->{contributor} = "Created";
        say "\tCreated Contributor" if $verbose;
        $row_process->{contributor_existed} = "FALSE";
    }
    else {
        $row_process->{error} = "Contributor create failed.";
        say "\tContributor creation failed for person $person->{id} org $org->{identifier} role <$role>" if $verbose;
        return;
    }

    return 1;
}

