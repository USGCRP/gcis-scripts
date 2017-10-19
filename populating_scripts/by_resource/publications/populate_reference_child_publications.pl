#!/usr/bin/env perl

=head1 NAME

populate_reference_child_publications.pl - Take bibliographical entries and populate their child publications in GCIS

=head1 DESCRIPTION

populate_reference_child_publications.pl creates publications based on reference
entries in GCIS.

If a matching publication already exists in GCIS, a new publication is not
added. The existing publication is linked to the reference.

'crossref.org' is used to obtain some information for articles, if the doi
is valid and in 'crossref.org'. PubMed ID is checked if the article URL matches
PubMed article types. CrossRef and PubMed data are preferred for the new resource
created.

Note: Only Articles, Reports and Web Pages are currently implemented. Articles
also create their journal, if needed.

=head1 SYNOPSIS

./populate_reference_child_publications.pl [OPTIONS]

=head1 OPTIONS

=over

=item B<--url>

GCIS url, e.g. http://data-stage.globalchange.gov

=item B<--reference_file>

input - File containing the references to populate. One per line.

=item B<stdout>

Various log information is written to 'stdout'

=item B<--wait>

Time to wait between GCIS updates (seconds; defaults to -1 - do not wait)

=item B<--qa_file>

QA file (yml) - will contain the information for each reference processed

=item B<--verbose>

Verbose option

=item B<--dry_run> or B<--n>

Dry run option

=back

=head1 EXAMPLES

./populate_reference_child_publications.pl -u http://data-stage.globalchange.gov \
                    -r references.xml -q qa_file.yml

=cut

use lib './lib';

use Data::Dumper;
use Gcis::Client;
use IO::File;
use Refs;
use CrossRef;
use Clone::PP qw(clone);
use YAML::XS;
use Getopt::Long;
use Pod::Usage;
use Time::HiRes qw(usleep);
use PubMed;
use Utils;

use strict;
use v5.14;
use warnings;

binmode STDIN, ':encoding(utf8)';
binmode STDOUT, ':encoding(utf8)';

GetOptions(
    'url=s'            => \(my $url),
    'reference_file=s' => \(my $reference_file),
    'wait=i'           => \(my $wait = -1),
    'qa_file=s'        => \(my $qa_file),
    'verbose'          => \(my $verbose),
    'dry_run|n'        => \(my $dry_run),
    'help|?'           => sub { pod2usage(verbose => 2) },
) or die pod2usage(verbose => 1);

pod2usage(msg => "missing url or reference file", verbose => 1) unless ($url && $reference_file);

## Data Maps

# Reference Type to GCIS Type
my %TYPE_MAP = (
#   'Book' => 'book',
   'Edited Book' => 'edited_book',
   'Electronic Book' => 'book',
   'Book Section' => 'book_section', 
   'Electronic Book Section' => 'book_section',
   'Report' => 'report',
   'Manuscript' => 'report',
   'Journal Article' => 'article',
   'Electronic Article' => 'generic_article',
   'Web Page' => 'webpage',
   'Dataset' => 'dataset',
   'Conference Paper' => 'generic_cpaper', 
   'Online Multimedia' => 'generic_media',
   'Legal Rule or Regulation' => 'generic_legal', 
   'Press Release' => 'generic_press', 
   'Aggregated Database' => 'generic_aggregateDB',
);

my %QAS;
my $N_UPDATES = 0;
my %STATS;

&main;

# # Turns a string into a GCIS-compatible word-based identifier

sub make_identifier {
    my $str = shift or return undef;
    my $max_char = shift;

    my @words = split /\s+/, $str;
    my $id = '';
    for (@words) {
        tr/A-Z/a-z/;
        tr/a-z0-9-//dc;
        next if /^(a|the|from|and|for|to|with|of|in)$/;
        next unless length;
        $id .= '-' if length($id);
        $id .= $_;
        if ($max_char) {
            last if $max_char > 0  &&  length($id) > $max_char;
        }
    }
    $id =~ s/-+/-/g;
    return $id;
}

# Utility Function to remove any undef values in a hash

sub remove_undefs {
    my $suspicious_hash = shift;
    ref $suspicious_hash eq 'HASH' or return 0;
    for (keys %{ $suspicious_hash }) {
        if (ref $suspicious_hash->{$_} eq 'HASH') {
            remove_undefs($suspicious_hash->{$_});
            undef $suspicious_hash->{$_} unless keys %{ $suspicious_hash->{$_} } > 0;
        }
        delete $suspicious_hash->{$_} unless defined $suspicious_hash->{$_};
    }
    return 1;
}

# Given a GCIS Handle and the new Resource's info hash, create the Resource in GCIS.

sub create_resource_in_gcis {
    my ($gcis_handle, $new_resource) = @_;

    my $new_resource_uri = $new_resource->{uri};
    my ($new_resource_path) = ($new_resource_uri =~ /^\/(.*?)\//);

    if ($dry_run) {
        #say " NOTE: would add $new_resource_path : $new_resource_uri";
        $N_UPDATES++;
        $STATS{"would_add_$new_resource_path"}++;
        return $new_resource->{uri};
    }

    #say " adding $new_resource_path : $new_resource_uri";
    $STATS{"added_$new_resource_path"}++;
    my $cloned_new_resource = clone($new_resource);
    remove_undefs($cloned_new_resource);
    delete $cloned_new_resource->{uri};
    if ($new_resource_path eq 'article') {
        delete $cloned_new_resource->{$_} for qw(uri author pmid);
    }
    $N_UPDATES++;
    my $created_resource = $gcis_handle->post("/$new_resource_path", $cloned_new_resource)
        or warn " unable to add $new_resource_path : $new_resource_uri";
    sleep($wait) if $wait > 0;

    return $created_resource->{uri} // undef;
}

# Given a GCIS Handle and the EndNote reference info, create the reference With a child_pub linked

sub connect_reference_and_child {
    my ($gcis_handle, $reference_uri, $child_pub_uri) = @_;

    if ($dry_run) {
        #say " NOTE: would assign child pub : $child_pub_uri to reference : $reference_uri";
        $N_UPDATES++;
        $STATS{would_add_child_pub}++;
        return 1;
    }

    #say " adding child pub : $child_pub_uri";
    $STATS{added_child_pub}++;
    $N_UPDATES++;
    my $ref = $gcis_handle->get($reference_uri);
    $gcis_handle->post($reference_uri, {
        child_publication_uri => $child_pub_uri,
        identifier => $ref->{identifier},
        attrs => $ref->{attrs},
        }) or warn " unable to connect child pub : $child_pub_uri to $reference_uri";
    sleep($wait) if $wait > 0;

    return 1;
}

# # Given a GCIS Handle, Resource Type, Resource Field and Value, try search GCIS for the resource.

sub _find_resource {
    my ($gcis_handle, $gcis_type, $search_field, $search_value) = @_;

    #say "Searching type $gcis_type, field $search_field, for value $search_value";
    my $search_value_formatted = $search_value;
    $search_value_formatted = Utils::url_unescape($search_value_formatted) if $search_field eq 'url';
    if ($search_field eq 'title') {
        $search_value_formatted = Utils::strip_title($search_value_formatted);
        $search_value_formatted = Utils::url_unescape($search_value_formatted);
    }
    $search_value_formatted =~ s/ +/+/g;
    my @search_results = $gcis_handle->get("/search?&q=$search_value_formatted&type=$gcis_type") or return undef;

    my ($search_match, $matched_on);
    for my $search_result (@search_results) {
        if ($search_result->{$search_field}) {
            if ($search_result->{$search_field} eq $search_value) {
                $search_match = $search_result;
                $matched_on = "Matched $search_field";
                last;
            }
        }
        if ($search_field eq 'print_issn') {
            next unless $search_result->{online_issn};
            if ($search_result->{online_issn} eq $search_value) {
                $search_match = $search_result;
                $matched_on = "Matched mismatched ISSNs";
            }
            last;
        } elsif ($search_field eq 'online_issn') {
            next unless $search_result->{print_issn};
            if ($search_result->{print_issn} eq $search_value) {
                $search_match = $search_result;
                $matched_on = "Matched mismatched ISSNs";
            }
            last;
        } elsif ($search_field eq 'title') {
            my $result_title = make_identifier($search_result->{$search_field}) or next;
            my $search_title = make_identifier($search_value) or next;
            if ($result_title eq $search_title) {
                $search_match = $search_result;
                $matched_on = "Matched identifier";
                last;
            }
        } elsif ($search_field eq 'url') {
            my $result_url = Utils::url_escape($search_result->{$search_field}) or next;
            my $search_url = Utils::url_escape($search_value) or next;
            if ($result_url eq $search_url) {
                $search_match = $search_result;
                $matched_on = "Matched URL";
                last;
            }
        }
    }

    return $search_match ? ($search_match, $matched_on) : undef;
}

# Given a GCIS Handle, Resource Type, and the Reference, find the GCIS equivalent if it exists.

sub find_existing_gcis_resource {
    my ($gcis_handle, $gcis_type, $reference ) = @_;

    my ($resource_gcis, $matched_on);
    for my $search_field (qw(DOI URL Title print_issn online_issn)) {
        next unless $reference->{$search_field};
        ($resource_gcis, $matched_on) = _find_resource($gcis_handle, $gcis_type, (lc $search_field), $reference->{$search_field});
        last if $resource_gcis;
    }

    # Kill bad matches with Differing DOIs
    if ($reference->{DOI} && $resource_gcis->{doi}) {
        if ( $reference->{DOI} ne $resource_gcis->{doi} ) {
            return undef;
        }
    }

    return $resource_gcis ? ($resource_gcis->{uri}, $matched_on) : undef;
}

sub import_journal_from_article {
    my %args = @_;

    my $reference        = $args{reference};
    my $article          = $args{article};
    my $external_article = $args{external_article};
    my $gcis_handle      = $args{gcis_handle};
    my $ref_data         = $reference->{attrs};

    # Build the Journal Resource
    my $journal;
    $journal->{title} = $ref_data->{Journal} or do {
        die " ERROR: no journal title : $article->{identifier} : $reference->{uri}";
    };

    if ( $external_article ) {
        $journal->{print_issn}  = $external_article->{issn}[0];
        $journal->{online_issn} = $external_article->{issn}[1];
        $journal->{publisher}   = $external_article->{publisher};
    }
    else {
        $journal->{print_issn}  = $ref_data->{ISSN};
    }
    # Pull any matching existing GCIS Journal
    my ($existing_journal_uri, $matched_on) = find_existing_gcis_resource($gcis_handle, 'journal', $journal);

    # Ensure we have some unique identifier for the Journal
    if ( ! $existing_journal_uri && ! $journal->{print_issn} ) {
        warn " ERROR: no journal issn : $journal->{uri} : $reference->{uri}";
        # QA out
        create_qa_entry(
            reference         => $reference,
            gcis_type         => 'journal',
            ref_type          => $reference->{attrs}{reftype},
            action            => 'Could not create Journal',
        );
        return;

    }

    my ($journal_identifier, $action);
    if ( ! $existing_journal_uri ) {
        $journal->{identifier} = make_identifier($journal->{title}) unless $journal->{identifier};
        $journal->{uri} = "/journal/$journal->{identifier}";
        print "         " . ( $dry_run ? "(DRYRUN) " : "") . "Creating new journal $journal->{uri}\n";
        $action = "Creating and linking journal to article.";
        create_resource_in_gcis($gcis_handle, $journal);
        $journal_identifier = $journal->{identifier};
    }
    else {
        my ($identifier) = $existing_journal_uri =~ m</[^/]+/(.*)>;
        print "         " . ( $dry_run ? "(DRYRUN) " : "") . "Found journal $existing_journal_uri\n";
        $action = "Linking existing journal to article.";
        $journal_identifier = $identifier;
    }

    # QA out
    create_qa_entry(
        reference         => $reference,
        child_publication => $journal_identifier,
        gcis_type         => 'journal',
        ref_type          => $reference->{attrs}{reftype},
        action            => $action,
    );

    return $journal_identifier;
}

sub build_resource {
    my %import_args = @_;

    my $gcis_handle = $import_args{gcis};
    my $reference   = $import_args{reference};
    my $type        = $import_args{gcis_type};
    my $resource;
    my $ref_data = $reference->{attrs};

    $STATS{"n_$type"}++;

    $resource->{title} = $ref_data->{Title};

    my $resource_key_map = {
        webpage => {
            URL => 'url', 
            Year => 'access_date',
        },
        report => {
            URL => 'url', 
            DOI  => 'doi', 
            Year => 'publication_year',
            Abstract => 'summary', 
        },
        article => {
            URL   => 'url',
            DOI    => 'doi', 
            Year   => 'year',
            Volume => 'journal_vol',
            Pages  => 'journal_pages',
        },
    };

    my $this_resource_key_map = $resource_key_map->{$type} or die "type missing key_map: $type";
    for (keys %{ $this_resource_key_map }) {
        next unless $ref_data->{$_};
        $resource->{$this_resource_key_map->{$_}} = $ref_data->{$_};
    }

    # cleanup access date
    if ($type eq 'webpage'  &&  $resource->{access_date}) {
        if ( $resource->{access_date} ) {
            delete $resource->{access_date} if $resource->{access_date} eq 'Undated';
            $resource->{access_date} .= "-01-01T00:00:00" if $resource->{access_date};
        }
        if ( ! $resource->{identifier} ) {
            my $uuids = $gcis_handle->get("/uuid.json");
            $resource->{identifier} = $uuids->[0];
        }
    }
    # cleanup publication year
    elsif ($type eq 'report'  &&  $resource->{publication_year}) {
       delete $resource->{publication_year} if $resource->{publication_year} eq 'n.d.';
    }
    elsif ($type eq 'article') {
        if ($resource->{doi}) {
            $resource->{identifier } = $resource->{doi}
        }

        # TODO - load articles from CrossRef; PubMed. Populate data from there.
        # Load external versions of the article, if they exist
        my $external_article;
        if ($resource->{doi}) {
            $resource->{identifier} = $resource->{doi};
            my $crossref_handle = CrossRef->new;
            $external_article = $crossref_handle->get($resource->{doi});
            if ($external_article) {
               source_external_info($resource, $external_article);
            }
        } elsif ( my $pmid = PubMed::alt_id($resource->{url}, $ref_data->{Pages}) ) {
            my $pubMed_handle = PubMed->new;
            $external_article = $pubMed_handle->get($pmid);
            if ($external_article) {
                $resource->{identifier} = 'pmid-'.$external_article->{pmid};
                #print "pm id: $resource->{identifier}\n"
            }
        }

        $resource->{journal_identifier} = import_journal_from_article(
            reference        => $reference,
            article          => $resource,
            external_article => $external_article,
            gcis_handle      => $gcis_handle,
        );
    }

    $resource->{identifier} = make_identifier($resource->{title}) unless $resource->{identifier};
    $resource->{uri} = "/$type/$resource->{identifier}";

    return $resource;
}

# We prefer the title, year, journal volume and journal pages from CrossRef, rather
# than the specification in the reference

sub source_external_info {
    my ($existing, $external) = @_;
    for my $field ( qw(title journal_vol journal_pages title) ) {
        $existing->{$field} = $external->{field} if $external->{field};
    }
    return;
}

# reference import_other
sub populate_child_publication {
    my %args = @_;
    my $reference = $args{reference};
    my $ref_type  = $args{ref_type};
    my $gcis_type = $args{gcis_type};
    my $gcis      = $args{gcis};

    my ($child_pub, $action);
    my ($existing_publication, $matched_on) =
            find_existing_gcis_resource($gcis, $gcis_type, $reference->{attrs});
    if ( $existing_publication ) {
        print "      Found existing publication '$existing_publication'. $matched_on\n";
        $child_pub = $existing_publication;
        $action = "Found & linked existing publication. $matched_on";
    }
    else {
        # create the publication - info grab from crossref
        print "      " . ( $dry_run ? "(DRYRUN) " : "") . "Creating new publication\n";
        my $resource_data = build_resource(
            reference => $reference,
            gcis_type => $gcis_type,
            gcis      => $gcis,
        );

        $child_pub = create_resource_in_gcis( $gcis, $resource_data);
        if ( $child_pub ) {
            $action = "Created & linked publication.";
        } else {
            $action = "Failed to create publication";
        }
        print "      " . ( $dry_run ? "(DRYRUN) " : "") . "Created publication: $child_pub\n";
    }

    # link the reference and the child publication
    connect_reference_and_child($gcis, $reference->{uri}, $child_pub);
    print "      " . ( $dry_run ? "(DRYRUN) " : "") . "Linked reference ($reference->{uri}) and child publication ($child_pub)\n";
    # QA out
    create_qa_entry(
        reference         => $reference,
        child_publication => $child_pub,
        gcis_type         => $gcis_type,
        ref_type          => $ref_type,
        action            => $action,
    );
    return;
}

sub dump_qa {

    my $n_refs = scalar keys %QAS;
    return 1 if $n_refs == 0  ||  !$qa_file;
    open my $f, '>:encoding(UTF-8)', "$qa_file" or die "can't open QA file";
    #print $f "$_\n" for ( @REFS );
    say $f Dump(\%QAS);
    close $f;

    return 1;

}

# Prints out our initial refs info

sub report_initial_state {
    # Report Options Settings
    say " populating references' child publications";
    say "   url : $url";
    say "   reference_file : $reference_file";
    say "   qa_file : $qa_file" if $qa_file;
    say "   verbose" if $verbose;
    say "   dry_run" if $dry_run;
    say '';

    return;
}

sub report_final_state {

    my $n_stat = 0;
    for (sort keys %STATS) {
        say "   $_ : $STATS{$_}";
        $n_stat += $STATS{$_};
    }
    #say " n stat : $n_stat";

    return;
}

sub load_reference_file {
    my @references;
    my $fh = IO::File->new($reference_file, "r");
    if (defined $fh) {
        chomp(@references = <$fh>);
        $fh->close;
    }
    return \@references;
}

sub create_qa_entry {
    my %args = @_;
    my $reference = $args{reference};

    $QAS{ $reference->{uri} } = {
        action    => $args{action},
        gcis_type => $args{gcis_type},
        ref_type  => $args{ref_type},
        child_publication => $args{child_publication},
    };
    return 1;
}

sub main {
    my $gcis = $dry_run ? Gcis::Client->new(url => $url)
                     : Gcis::Client->connect(url => $url);

    my $references = load_reference_file();

    report_initial_state();

    my %types_to_process = (
        article => 1,
        report  => 1,
        webpage => 1,
    );

    foreach my $ref_uri (@{ $references }) {
        my $reference = $gcis->get($ref_uri);

        #print Dumper $reference;
        #
        print "Handling Reference: $ref_uri\n";

        my $ref_type = $reference->{attrs}{reftype};
        my $type = $TYPE_MAP{$ref_type} // '';

        if ( $reference->{child_publication} ) {
            print "   Reference already has child pub $reference->{child_publication}\n";
            $STATS{reference_has_child_pub}++;
            create_qa_entry(
                reference => $reference,
                gcis_type => $type,
                ref_type  => $ref_type,
                child_publication => $reference->{child_publication},
                action    => "Skipped - Child Publication Preexisting",
            );
        }
        elsif ( ! $type ) {
            print "   Reference type $ref_type has no GCIS type mapping\n";
            $STATS{reference_type_unknown}++;
            create_qa_entry(
                reference => $reference,
                gcis_type => $type,
                ref_type  => $ref_type,
                action    => "Skipped - Unknown type: $reference->{attrs}{reftype}",
            );
        }
        elsif ( $types_to_process{ $type } ) {
            print "   Handling child publication for reference: $reference->{attrs}{Title}\n";
            populate_child_publication(
                reference => $reference,
                gcis_type => $type,
                ref_type  => $ref_type,
                gcis      => $gcis,
            );
        }
        else {
            print "   Reference type $ref_type ($type) is not handled in this script.\n";
            $STATS{reference_type_not_automated}++;
            $STATS{"n_$type"}++;
            create_qa_entry(
                reference => $reference,
                gcis_type => $type,
                ref_type  => $ref_type,
                action    => "Skipped - Unautomated Pub Type",
            );
        }
    }

    dump_qa();
    report_final_state();

    return;
}
