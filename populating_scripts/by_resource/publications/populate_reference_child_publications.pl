#!/usr/bin/env perl

=head1 NAME

populate_reference_child_publications.pl - Take bibliographical entries and populate their child publications in GCIS

=head1 DESCRIPTION

populate_reference_child_publications.pl creates publications based on reference
entries in GCIS.

If a matching publication already exists in GCIS, a new publication is not
added. The existing publication is linked to the reference.

'crossref.org' is used to obtain some information for articles, if the doi
is valid and in 'crossref.org'. It's data is preferred for the new resource
created.

Note: Only Articles, Reports and Web Pages are currently implemented.

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

QA file (csv) - will contain the URIs for each reference processed

=item B<--verbose>

Verbose option

=item B<--dry_run> or B<--n>

Dry run option

=back

=head1 EXAMPLES

./populate_reference_child_publications.pl -u http://data-stage.globalchange.gov 
                    -e references.xml

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

# to delete.
my %DO_NOT_ADD = (
    journals   => 0,
    references => 0,
    report     => 0,
    webpage    => 0,
    article    => 0,
    journal    => 0,
);

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

# type => { EndNote_Key => "GCIS Reference Key" }
my $BIB_TYPE_KEY_MAP = {
    article => {
        'Date Published' => 'Date',
        'Publisher' => '.publisher',
        'Publication Title' => undef,
        'Secondary Title' => 'Journal', 
        'ISBN' => undef, 
    },
    edited_book => {
        'Issue' => 'Edition',
        'Pages' => 'Number of Pages',
        'Author' => 'Editor',
    },
    book => {
        'Issue' => 'Edition', 
        'Pages' => 'Number of Pages',
        'Secondary Author' => 'Editor', 
    },
    book_section => {
        'Secondary Title' => 'Book Title', 
        'Issue' => 'Edition',
        'Secondary Author' => 'Editor',
    },
    generic_legal => {
    },
    generic_press => {
    },
    generic_media => {
        'Secondary Title' => 'Periodical Title', 
        'Date' => 'E-Pub Date', 
    },
    generic_cpaper => {
        'Place Published' => 'Conference Location', 
        'Secondary Title' => 'Conference Name', 
        'Year' => 'Year of Conference',
    },
    report => {
        'Issue' => 'Number', 
    },
    webpage => {
        'Issue' => 'Number', 
    },
};

my %REF_TYPE_NUM = (
   article => 0,
   book => 9,
   edited_book => 9,
   book_section => 7,
   generic_legal => 32,
   generic_press => 63,
   generic_media => 48,
   generic_cpaper => 47,
   report => 10,
   webpage => 16,
);

# EndNote references key to GCIS Reference key
my %BIB_MAP = (
    abstract            => 'Abstract',
    doi                 => 'DOI',
    isbn                => 'ISBN',
    issn                => 'ISSN', 
    language            => 'Language',
    notes               => 'Notes',
    number              => 'Issue',
    pages               => 'Pages',
    pub_dates           => 'Date Published',
    pub_location        => 'Place Published',
    publisher           => 'Publisher',
    record_number       => '_record_number',
    ref_key             => '_uuid',
    reftype             => 'reftype',
    reftype_id          => '.reference_type',
    urls                => 'URL', 
    volume              => 'Volume',
    year                => 'Year',
    author              => 'Author',
    keywords            => 'Keywords',
    secondary_author    => 'Secondary Author',
    secondary_title     => 'Secondary Title',
    pub_title           => 'Publication Title', 
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
        return 1;
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
    my $created_resource = $gcis_handle->post("/$new_resource_path", $cloned_new_resource) or die " unable to add $new_resource_path : $new_resource_uri";
    sleep($wait) if $wait > 0;

    return $created_resource->{uri};
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
        }) or die " unable to add child pub : $child_pub_uri";
    sleep($wait) if $wait > 0;

    return 1;
}

# # Given a GCIS Handle, Resource Type, Resource Field and Value, try search GCIS for the resource.

sub _find_resource {
    my ($gcis_handle, $gcis_type, $search_field, $search_value) = @_;

    say "Searching type $gcis_type, field $search_field, for value $search_value";
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
    #for my $max_char (-1, 60, 40, 30) {
    #my $id = make_identifier($reference->{Title}, $max_char);
    #$resource_gcis = $gcis_handle->get("/$gcis_type/$id");
    #if ($resource_gcis){
    #$matched_on = "Matched identifier at limited length: $max_char";
    #last;
    #}
    #}

    # Kill bad matches with Differing DOIs
    if ($reference->{DOI} && $resource_gcis->{doi}) {
        if ( $reference->{DOI} ne $resource_gcis->{doi} ) {
            return undef;
        }
    }

    return $resource_gcis ? ($resource_gcis->{uri}, $matched_on) : undef;
}

# 
# sub import_article {
#     my $import_args = shift;
# 
#     my $gcis_handle = $import_args->{gcis};
#     my $errata      = $import_args->{errata};
#     my $ref_handler = $import_args->{ref};
#     my $article;
# 
#     say " ---";
#     $STATS{n_article}++;
# 
#     # Pull article information out of the EndNote reference
#     # To build the Article Resource
#     $article->{title} = xml_unescape(join ' ', @{ $ref_handler->{title} }) or do {
#         say " ERROR: no title! : $ref_handler->{record_number}[0] : $ref_handler->{ref_key}[0]";
#         $STATS{no_title}++;
#         return 0;
#     };
#     for ($article->{title}) {
#         s/\(\s+/\(/g;  s/\s+\)/\)/g;
#     }
# 
#     my $article_key_map = {
#         urls   => 'url',
#         doi    => 'doi', 
#         year   => 'year',
#         volume => 'journal_vol',
#         pages  => 'journal_pages',
#     };
#     for (keys %{ $article_key_map }) {
#         next unless $ref_handler->{$_};
#         $article->{$article_key_map->{$_}} = $ref_handler->{$_}[0];
#     }
#     $article->{author} = xml_unescape(join '; ', @{ $ref_handler->{author} });
# 
#     # break out any Key-Value pairs noted as alternate ids
#     fix_alt_id($import_args->{alt_ids}, \%{ $article });
# 
#     # Clean up our External Identifiers
#     if ($article->{doi}) {
#         fix_doi($errata, $article);
#     } elsif (!$article->{pmid}) {
#         $article->{pmid} = PubMed::alt_id($article->{url}, $ref_handler->{pages}[0]) or do
#         {
#             say " WARN: no doi or alternate id : $article->{title} : $ref_handler->{record_number}[0] : $ref_handler->{ref_key}[0]";
#             $STATS{no_doi_or_alternate_id}++;
#         };
#     }
# 
#     # Load external versions of the article, if they exist
#     my $external_article;
#     my $check_external = 0;
#     if ($article->{doi}) {
#         my $crossref_handle = CrossRef->new;
#         $external_article = $crossref_handle->get($article->{doi});
#         if (!$external_article) {
#             say " WARN: doi not in crossref : $article->{doi} : $ref_handler->{record_number}[0] : $ref_handler->{ref_key}[0]";
#             $STATS{doi_not_in_crossref}++;
#        } else {
#             $check_external = 1;
#             $article->{identifier} = $article->{doi};
#        }
#     } elsif ($article->{pmid}) {
#        my $pubMed_handle = PubMed->new;
#        $external_article = $pubMed_handle->get($article->{pmid}); 
#        if (!$external_article) {
#            say " WARN: id not in pubmed : $article->{pmid}\n   for : $article->{title} : $ref_handler->{record_number}[0] : $ref_handler->{ref_key}[0]";
#            $STATS{id_not_in_pubmed}++;
#        } else {
#            $check_external = 1;
#            $article->{identifier} = 'pmid-'.$external_article->{pmid};
#            $article->{pmid} = $external_article->{pmid};
#        }
#     }
#     # Fallback on the GCIS version of the article
#     if (!$external_article) {
#        $external_article = get_item($gcis_handle, 'article', $article);
#     }
# 
#     $article->{uri} = "/article/$article->{identifier}";
#     #my $uri = $article->{uri};# or return 0;
#     #say "DEBUG: Found A Resourse URI";
#     #my $uri_errata = $errata->{e}->{$uri} ;#or return 1;
#     #for (@{ $uri_errata }) {
#     #    say "Fixing Errata! Here's the _ for array { i }:";
#     #    say Dumper $_;
#     #    $errata->_fix_items($_, $article);
#     #}
# 
#     say " art :\n".Dumper($article) if $verbose;
# 
#     # Assert the article matches the external
#     if ($check_external) {
#         my $ignored = $errata->diff_okay($article);
#         $ignored->{$_} = 1 for qw(uri identifier journal_identifier url);
#         my $difference = compare_hash($article, $external_article, $ignored);
#         if ($difference) {
#             add_to_diff($article->{uri}, $difference);
#             say " NOTE: external source article different : $article->{uri}";
#             print " DEBUG ";
#             print Dumper $difference;
#             $STATS{external_source_article_different}++;
#            return 0; # TODO Should this really return...?
#         }
#     }
# 
#     # Handle Updating or Adding the article
#     my $articleGCIS = $gcis_handle->get($article->{uri});
#     if ($articleGCIS) {
#         update_existing_resource(
#           existing    => $articleGCIS,
#           new         => $article,
#           errata      => $errata,
#           gcis_handle => $gcis_handle,
#           type        => 'article',
#         );
#     } elsif (!$DO_NOT_ADD{article} ) {
#        add_item($gcis_handle, $article) or return 0;
#     } else {
#        return 0;
#     }
# 
#     # Creating the Reference
#     my $article_reference;
#     $article_reference->{identifier} = $ref_handler->{ref_key}[0];
#     $article_reference->{uri} = "/reference/$article_reference->{identifier}";
#     my $reference_attrs = \%{ $article_reference->{attrs} };
# 
#     # clean up the attr keys
#     ## general key name mapping
#     map_attrs($ref_handler, $reference_attrs);
# 
#     ## kill extraneous fields
#     for ('Publication Title', 'Secondary Title', 'ISBN') {
#         next unless $reference_attrs->{$_};
#         delete $reference_attrs->{$_};
#     }
# 
#     ## article-specific key name mapping
#     my $extra_map = {
#         'Date Published' => 'Date',
#         'Publisher' => '.publisher',
#     };
#     for (keys %{ $extra_map }) {
#         next unless $reference_attrs->{$_};
#         $reference_attrs->{$extra_map->{$_}} = $reference_attrs->{$_};
#         delete $reference_attrs->{$_};
#     }
# 
#     # Overwrite these fields with the endnote values, but gcis keys
#     my $article_field_map = {
#         author        => 'Author', 
#         title         => 'Title', 
#         url           => 'URL',
#         doi           => 'DOI',
#         journal_pages => 'Pages', 
#         journal_vol   => 'Volume',
#         year          => 'Year', 
#         pmid          => 'PMID', 
#     };
#     foreach my $endnote_key (keys %{ $article_field_map }) {
#         my $gcis_key = $article_field_map->{$endnote_key};
#         if (!defined $article->{$endnote_key}) {
#             next unless $reference_attrs->{$gcis_key};
#             delete $reference_attrs->{$gcis_key};
#             next;
#         }
#         $reference_attrs->{$gcis_key} = $article->{$endnote_key};
#     }
# 
#     # Add extra attrs and fix errata TODO
#     $reference_attrs->{'.reference_type'} = 0;
#     $reference_attrs->{ISSN} = $journal->{online_issn} ? $journal->{online_issn} : $journal->{print_issn};
#     $reference_attrs->{Journal} = $journal->{title};
# 
#     $errata->fix_errata($article_reference);
# 
#     say " bib :\n".Dumper($article_reference) if $verbose;
# 
#     #push @QAS, $article_reference->{uri};
#     # Update or Add the reference
#     # Handle the DIFF issues in the update
#     my $existing_gcis_ref = $gcis_handle->get($article_reference->{uri});
#     if ($existing_gcis_ref) {
#         fix_bib_issn($reference_attrs, $existing_gcis_ref->{attrs}, $journal);
#         my $ignored = $errata->diff_okay($article_reference);
#         $ignored->{_record_number} = 1;
#         my $difference = compare_hash($article_reference, $existing_gcis_ref, $ignored);
#             print " DEBUG ";
#             print Dumper $difference;
#         if ($difference) {
#             say " NOTE: existing reference different : $article_reference->{uri}";
#             $STATS{existing_reference_different}++;
#             if (can_fix_item($difference)  ) {
#                 say " NOTE: can fix reference: $article_reference->{uri}";
#                 $STATS{"can_fix_reference"}++;
#                 fix_item($article_reference, $existing_gcis_ref, $ignored);
#                 my $fixed_diff = compare_hash($article_reference, $existing_gcis_ref, $ignored);
#                 !$fixed_diff or die "didn't fix reference!";
#                 update_item($gcis_handle, $existing_gcis_ref);
#                 return 0 if $DO_NOT_ADD{ references }  ||
#                             $existing_gcis_ref->{child_publication};
#             } else {
#                 add_to_diff($article_reference->{uri}, $difference);
#                 return 0;
#             }
#         } else {
#             say " NOTE: existing reference same : $article_reference->{uri}";
#             $STATS{existing_reference_same}++;
#             return 0 if $DO_NOT_ADD{ references }  ||  
#                         $existing_gcis_ref->{child_publication};
#         }
#     } elsif (!$DO_NOT_ADD{ references }) {
#         add_item($gcis_handle, $article_reference) or return 0;
#     } else {
#         return 0;
#     }
# 
#     # Connect the child publication
#     $article_reference->{child_publication_uri} = $article->{uri};
#     add_child_pub($gcis_handle, $article_reference) or return 0;
# 
#     return 1;
# }

sub import_journal_from_article {
    my %args = @_;

    my $reference        = $args{reference};
    my $article          = $args{article};
    my $external_article = $args{external_article};
    my $gcis_handle      = $args{gcis_handle};

    # Build the Journal Resource
    my $journal;
    $journal->{title} = $reference->{Journal} or do {
        die " ERROR: no journal title : $article->{identifier} : $reference->{uri}";
    };

    if ( $external_article ) {
        $journal->{print_issn}  = $external_article->{issn}[0];
        $journal->{online_issn} = $external_article->{issn}[1];
        $journal->{publisher}   = $external_article->{publisher};
    }
    else {
        $journal->{print_issn}  = $reference->{ISSN};
    }
    # Pull any matching existing GCIS Journal
    my ($existing_journal, $matched_on) = find_existing_gcis_resource($gcis_handle, 'journal', $journal);

    # Ensure we have some unique identifier for the Journal
    if ( ! $existing_journal && ! $journal->{print_issn} ) {
        die " ERROR: no journal issn : $journal->{uri} : $reference->{uri}";
    }


    if ( ! $existing_journal ) {
        $journal->{identifier} = make_identifier($journal->{title}) unless $journal->{identifier};
        $journal->{uri} = "/journal/$journal->{identifier}";
        my $journal_uri = create_resource_in_gcis($gcis_handle, $journal);
        return $journal_uri;
    }
    else {
        return $existing_journal;
    }
}


sub build_resource {
    my %import_args = @_;

    my $gcis_handle = $import_args{gcis};
    my $reference   = $import_args{ref_data};
    my $type        = $import_args{gcis_type};
    my $resource;

    $STATS{"n_$type"}++;

    # Data pull.
    # Should get out: Title

    $resource->{title} = $reference->{Title};

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
        next unless $reference->{$_};
        $resource->{$this_resource_key_map->{$_}} = $reference->{$_};
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

        my $external_article;
        # TODO - load articles from CrossRef; PubMed. Populate data from there.
        # Load external versions of the article, if they exist
        #my $article = $resource;
        #my $external_article;
        #my $check_external = 0;
        #if ($article->{doi}) {
        #    my $crossref_handle = CrossRef->new;
        #    $external_article = $crossref_handle->get($article->{doi});
        #    if (!$external_article) {
        #        say "\t\t\tDOI not in crossref : $article->{doi} : $article->{title} : $reference->{uri}";
        #        $STATS{doi_not_in_crossref}++;
        #   } else {
        #        $check_external = 1;
        #        $article->{identifier} = $article->{doi};
        #   }
        #} elsif ( $article->{pmid} = PubMed::alt_id($article->{url}, $reference->{Pages}) ) {
        #   my $pubMed_handle = PubMed->new;
        #   $external_article = $pubMed_handle->get($article->{pmid});
        #   if (!$external_article) {
        #       say "\t\t\tPubMed ID not in pubmed : $article->{pmid} : $article->{title} : $reference->{uri}";
        #       $STATS{id_not_in_pubmed}++;
        #   } else {
        #       $check_external = 1;
        #       $article->{identifier} = 'pmid-'.$external_article->{pmid};
        #       $article->{pmid} = $external_article->{pmid};
        #   }
        #}
        #

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
        print "\t\tFound existing publication '$existing_publication'. $matched_on\n";
        $child_pub = $existing_publication;
        $action = "Found & linked existing publication. $matched_on";
    }
    else {
        # create the publication - info grab from crossref
        print "\t\t" . ( $dry_run ? "(DRYRUN) " : "") . "Creating new publication\n";
        my $resource_data = build_resource(
            ref_data  => $reference->{attrs},
            gcis_type => $gcis_type,
            gcis      => $gcis,
        );

        $child_pub = create_resource_in_gcis( $gcis, $resource_data);
        $action = "Created & linked publication.";
        print "\t\t" . ( $dry_run ? "(DRYRUN) " : "") . "Created publication: $child_pub\n";
    }

    # link the reference and the child publication
    connect_reference_and_child($gcis, $reference->{uri}, $child_pub);
    print "\t\t" . ( $dry_run ? "(DRYRUN) " : "") . "Linked reference ($reference->{uri}) and child publication ($child_pub)\n";
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
            print "\tReference already has child pub $reference->{child_publication}\n";
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
            print "\tReference type $ref_type has no GCIS type mapping\n";
            $STATS{reference_type_unknown}++;
            create_qa_entry(
                reference => $reference,
                gcis_type => $type,
                ref_type  => $ref_type,
                action    => "Skipped - Unknown type: $reference->{attrs}{reftype}",
            );
        }
        elsif ( $types_to_process{ $type } ) {
            print "\tHandling child publication for reference: $reference->{attrs}{Title}\n";
            populate_child_publication(
                reference => $reference,
                gcis_type => $type,
                ref_type  => $ref_type,
                gcis      => $gcis,
            );
        }
        else {
            print "\tReference type $ref_type ($type) is not handled in this script.\n";
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
