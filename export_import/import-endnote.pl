#!/usr/bin/env perl

=head1 NAME

import-endnote.pl -- Import bibliographical entries from an EndNote xml dump

=head1 DESCRIPTION

import-endnote.pl imports bibliographical entries to a GCIS instance from an
xml dump of an EndNote file.  The biblio entry is checked aganist existing
information in GCIS before import.

The program first add journal information, then article information and then
the reference information.  This program does not link to the reference to a
report, this needs to be done seperately.  The EndNote entry 'custom4' is used
as the reference identifier to enable the links to be added later.

If there a difference between existing
GCIS information and the new entry, no new information is added to GCIS.
If a matching entry already exists in GCIS, the new entry is not added.

'crossref.org' is used to obtain some information for the journals and 
articles.  The doi must be valid and in 'crossref.org' or the 
entry is not added.

An errata file may be used to ignore differences between the GCIS (or crossref)
entry and the EndNote file.  This allows for the new entry obtained from 
EndNote to be different from the information stored in GCIS (the GCIS 
information is not changed).

A file containing my be given contining a set of alternate ids 
that are based on the url.

[Note: Only EndNote Journal Articles, Reports and Web Pages are currently implemented.]

=head1 SYNOPSIS

./import-endnote.pl [OPTIONS]

=head1 OPTIONS

=over

=item B<--url>

GCIS url, e.g. http://data-stage.globalchange.gov

=item B<--endnote_file>

xml dump of an EndNote file

=item B<stdout>

Various log information is written to 'stdout'

=item B<--max_updates>

Maximum number of entries to update (defaults to 10; 
set to -1 update all)

=item B<--max_references>

Maximum number of references to read from the Endnote file 
(defaults to 40; set to -1 to read all)

=item B<--do_not_add_journals>

Flag indicating journals are not to be added

=item B<--do_not_add_items>

Flag indicating items (articles, web pages, etc.) are not to be added. Does not cover journals

=item B<--do_not_add_references>

Flag indicating references are not to be added

=item B<--wait>

Time to wait between GCIS updates (seconds; defaults to -1 - do not wait)

=item B<--errata_file>

Errata file (yaml) - contains aliases for entries that
already exists (see below for file example)

=item B<--diff_file>

Difference file (yaml) - contains differences between the new
entry and an existing GCIS entry

=idem B<--alt_id_file>

Alternate id file (yaml) containing a mapping between a url
and an alternate id.

=item B<--verbose>

Verbose option

=item B<--dry_run> or B<--n>

Dry run option

=back

=head1 EXAMPLES

# add a set of references to GCIS from an endnote file:

./import-endnote.pl -u http://data-stage.globalchange.gov 
                    -e endnote.xml

Example errata file (value corresponds to GCIS, alias to input):

---
article:
- uri: /reference/one-with-an-issue
  errata:
  - item: print_issn
    value: 0001-0002
    alias: 9991-9992

Items in the difference file can be converted to errata items, 
but each item should be carefully considered.

Example alternate id file:

---
- uri: 'http://my.url.com/unique-url.html'
  id: pmid-id
   

=cut

use lib './lib';

use Data::Dumper;
use Gcis::Client;
use Refs;
use CrossRef;
use Errata;
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
    'url=s'                 => \(my $url),
    'endnote_file=s'        => \(my $endnote_file),
    'max_updates=i'         => \(my $max_updates = 10),
    'max_references=i'      => \(my $max_references = 40),
    'do_not_add_journals'   => \(my $do_not_add_journals),
    'do_not_add_items'      => \(my $do_not_add_items),
    'do_not_add_referneces' => \(my $do_not_add_references),
    'wait=i'                => \(my $wait = -1),
    'errata_file=s'         => \(my $errata_file),
    'diff_file=s'           => \(my $diff_file),
    'alt_id_file=s'         => \(my $alt_id_file), 
    'verbose'               => \(my $verbose),
    'dry_run|n'             => \(my $dry_run),
    'help|?'                => sub { pod2usage(verbose => 2) },
) or die pod2usage(verbose => 1);

pod2usage(msg => "missing url or endnote file", verbose => 1) unless ($url && $endnote_file);

## Data Maps

my %TYPE_MAP = (
   'Book' => 'book',
   'Edited Book' => 'book',
   'Electronic Book' => 'book',
   'Book Section' => 'book_section', 
   'Electronic Book Section' => 'book_section',
   'Report' => 'report',
   'Manuscript' => 'report',
   'Journal Article' => 'article',
   'Web Page' => 'webpage',
   'Dataset' => 'dataset',
   'Conference Paper' => 'generic_cpaper', 
   'Online Multimedia' => 'generic_media',
   'Legal Rule or Regulation' => 'generic_legal', 
   'Press Release' => 'generic_press', 
   'Aggregated Database' => 'generic_aggregateDB',
);

my $BIB_TYPE_KEY_MAP = {
    article => {
        'Date Published' => 'Date',
        'Publisher' => '.publisher',
        'Publication Title' => undef,
        'Secondary Title' => 'Journal', 
        'ISBN' => undef, 
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
   book_section => 7,
   generic_legal => 32,
   generic_press => 63,
   generic_media => 48,
   generic_cpaper => 47,
   report => 10,
   webpage => 16,
);

my %BIB_MAP = (
    abstract      => 'Abstract',
    doi           => 'DOI',
    isbn          => 'ISBN',
    issn          => 'ISSN', 
    language      => 'Language',
    notes         => 'Notes',
    number        => 'Issue',
    pages         => 'Pages',
    pub_dates     => 'Date Published',
    pub_location  => 'Place Published',
    publisher     => 'Publisher',
    record_number => '_record_number',
    ref_key       => '_uuid',
    reftype       => 'reftype',
    reftype_id    => '.reference_type',
    urls          => 'URL', 
    volume        => 'Volume',
    year          => 'Year',
);

my %BIB_MULTI = (
    author => 'Author',
    keywords => 'Keywords',
    secondary_author => 'Secondary Author',
    secondary_title => 'Secondary Title',
    pub_title => 'Publication Title', 
);


my %DIFF;
my $N_UPDATES = 0;
my %STATS;
my $skip_dois = 1;
my $do_fix_items = 1;

&main;

# Utility Function to convert XML escaped values into plaintext

sub xml_unescape {
  my $str = shift;
  return undef unless defined($str);

 # for ($str) {
 #     s/\xe2\x96\x92\x7e//g;
 #     s/\xc3\xa2\x40/-/g;
 #     s/\x43\x45/\xc3\x85/g;
 #     s/\x43\xc2/\xc3\xb6/g;
 # }

  for ($str) {
      s/&quot;/"/g;
      s/&amp;/&/g;  s/&#39;/'/g;
      s/&#40;/(/g;  s/&#41;/)/g;
      s/&#44;/-/g;
      s/&#58;/:/g;  s/&#59;/;/g;
      s/&lt;/</g;   s/&gt;/>/g;
      s/&#91;/[/g;  s/&#92;/]/g;
      s/&#8211;/-/g;
  }

  return $str;
}

# Turns a string into a GCIS-compatible word-based identifier

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

# Utility Function to compare two hashes and return a DIFF set
# TODO why? 

sub compare_hash {
    my ($hash_a, $hash_b, $ignore) = @_;

    my %hash_result;
    for (keys %{ $hash_a }) {
        next if $ignore->{$_};
        next if !defined $hash_a->{$_}  &&  !defined $hash_b->{$_};
        if (!defined $hash_b->{$_}) {
           $hash_result{$_} = {_A_ => $hash_a->{$_}, _B_ => undef};
           next;
        }
        if (!defined $hash_a->{$_}) {
           $hash_result{$_} = {_A_ => undef, _B_ => $hash_b->{$_}};
           next;
        }
        if (ref $hash_a->{$_} eq 'HASH') {
            my $hash_c1 = compare_hash($hash_a->{$_}, $hash_b->{$_}, $ignore) or next;
            $hash_result{$_} = $hash_c1;
            next;
        }
        next if $hash_a->{$_} eq $hash_b->{$_};
        my $hash_a1 = lc xml_unescape($hash_a->{$_});
        my $hash_b1 = lc xml_unescape($hash_b->{$_});
        for ($hash_a1, $hash_b1) {
            s/^\s+//; s/\s+$//; s/\.$//; s/\r/; /g;
        }
        next if $hash_a1 eq $hash_b1;
        if (lc $_ eq 'author') {
            next if compare_author($hash_a1, $hash_b1);
        }
        $hash_result{$_} = {_A_ => $hash_a->{$_}, _B_ => $hash_b->{$_}};
    }
    return %hash_result ? \%hash_result : undef;
}

# Utility Function to compare if two authors are the same

sub compare_author {
    my ($author_a, $author_b) = @_;
    my @author_a1 = split '; ', $author_a;
    my @author_b1 = split '; ', $author_b;
    for my $author_a2 (@author_a1) {
        my $author_b2 = shift @author_b1;
        return 0 unless $author_b2;
        my ($author_al, $author_af) = split ', ', $author_a2;
        my ($author_bl, $author_bf) = split ', ', $author_b2;
        return 0 if $author_al ne $author_bl;
        next if !$author_af && !$author_bf;
        return 0 if $author_af && !$author_bf;
        return 0 if $author_bf && !$author_af;
        return 0 if substr($author_af, 0, 1) ne substr($author_bf, 0, 1);
    }
    return 1;
}

# Utility Function to remove any undef values in a hash
# TODO why?

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

# Given a GCIS Handle and the new Resource's info hash, update the Resource in GCIS.

sub update_item {
    my ($gcis_handle, $gcis_resource) = @_;

    my $resource_uri = $gcis_resource->{uri};
    my ($resource_path) = ($resource_uri =~ /^\/(.*?)\//);

    if ($dry_run) {
        say " would update $resource_path : $resource_uri";
        $N_UPDATES++;
        $STATS{"would_update_$resource_path"}++;
        return 1;
    }

    say " updating $resource_path : $resource_uri";
    $STATS{"updated_$resource_path"}++;
    my $cloned_resource = clone($gcis_resource);
    remove_undefs($cloned_resource);
    delete $cloned_resource->{uri};
    my @extra = qw(articles child_publication cited_by 
                   contributors files href 
                   parents publications references);
    push @extra, qw(chapters report_figures 
                    report_findings report_tables) if $resource_path eq 'report';
    for (@extra) {
        delete $cloned_resource->{$_} if $cloned_resource->{$_};
    }
    $N_UPDATES++;
    my $updated_resource = $gcis_handle->post($resource_uri, $cloned_resource) or die " unable to update $resource_path : $resource_uri";
    sleep($wait) if $wait > 0;

    return $updated_resource->{uri};
}

# Given a GCIS Handle and the new Resource's info hash, create the Resource in GCIS.

sub add_item {
    my ($gcis_handle, $new_resource) = @_;

    my $new_resource_uri = $new_resource->{uri};
    my ($new_resource_path) = ($new_resource_uri =~ /^\/(.*?)\//);

    if ($dry_run) {
        say " NOTE: would add $new_resource_path : $new_resource_uri";
        $N_UPDATES++;
        $STATS{"would_add_$new_resource_path"}++;
        return 1;
    }

    say " adding $new_resource_path : $new_resource_uri";
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

# given a hash of diffs, determine if this hash can be fixed by the script

sub can_fix_item {
    my $diff_hash = shift;
    return 0 unless $diff_hash;
    for (keys %{ $diff_hash }) {
        my $value = $diff_hash->{$_};
        if (!grep "_A_" eq $_, keys %{ $value }) {
            return 0 unless can_fix_item($value);
            next;
        }
        return 0 unless defined $value->{_A_};
        return 0 if defined $value->{_B_};
    }
    return 1;
}

# Given three hashes with existing value, fixed values, and values to ignore
# Update the values in the fixed hash to be correct.
# TODO: what does 'fix' imply here?

sub fix_item {
    my ($existing, $fixed, $ignore) = @_;
    for (keys %{ $existing }) {
        next if $ignore->{$_};
        if (ref $existing->{$_} eq 'HASH') {
            fix_item($existing->{$_}, $fixed->{$_}, $ignore);
            next;
        }
        next unless defined $existing->{$_};
        next if defined $fixed->{$_};
        $fixed->{$_} = $existing->{$_};
    }
    return 1;
}

# Given a GCIS Handle and the EndNote reference info, create the reference With a child_pub linked

sub add_child_pub {
    my ($gcis_handle, $child_pub_ref) = @_;

    my $child_pub_uri = $child_pub_ref->{uri};

    if ($dry_run) {
        say " NOTE: would assign child pub : $child_pub_ref->{identifier} to reference : $child_pub_uri";
        $N_UPDATES++;
        $STATS{would_add_child_pub}++;
        return 1;
    }

    say " adding child pub : $child_pub_uri";
    $STATS{added_child_pub}++;
    my $cloned_child_pub = clone($child_pub_ref->{attrs});
    remove_undefs($cloned_child_pub);
    $N_UPDATES++;
    $gcis_handle->post($child_pub_uri, {
        identifier => $child_pub_ref->{identifier},
        attrs => $cloned_child_pub,
        child_publication_uri => $child_pub_ref->{child_publication_uri},
        }) or die " unable to add child pub : $child_pub_uri";
    sleep($wait) if $wait > 0;

    return 1;
}

# Given a GCIS Handle, Resource Type, Resource Field and Value, try search GCIS for the resource.

sub find_item {
    my ($gcis_handle, $gcis_type, $search_field, $search_value) = @_;

    my $search_value_formatted = $search_value;
    $search_value_formatted = Utils::url_unescape($search_value_formatted) if $search_field eq 'url';
    if ($search_field eq 'title') {
        $search_value_formatted = Utils::strip_title($search_value_formatted);
        $search_value_formatted = Utils::url_unescape($search_value_formatted);
    }
    $search_value_formatted =~ s/ +/+/g;
    my @search_results = $gcis_handle->get("/search?&q=$search_value_formatted&type=$gcis_type") or return undef;

    for my $search_result (@search_results) {
        if ($search_result->{$search_field}) {
            return $search_result if $search_result->{$search_field} eq $search_value;
        }
        if ($search_field eq 'print_issn') {
            next unless $search_result->{online_issn};
            return $search_result if $search_result->{online_issn} eq $search_value;
        } elsif ($search_field eq 'online_issn') {
            next unless $search_result->{print_issn};
            return $search_result if $search_result->{print_issn} eq $search_value;
        } elsif ($search_field eq 'title') {
            my $result_title = make_identifier($search_result->{$search_field}) or next;
            my $search_title = make_identifier($search_value) or next;
            return $search_result if $result_title eq $search_title;
        } elsif ($search_field eq 'url') {
            my $result_url = Utils::url_escape($search_result->{$search_field}) or next;
            my $search_url = Utils::url_escape($search_value) or next;
            return $search_result if $result_url eq $search_url;
        }
    }
    return undef;
}

# Given a GCIS Handle, Resource Type, and the EndNote info, find the GCIS equivalent if it exists.

sub get_item {
    my ($gcis_handle, $gcis_type, $resource_info ) = @_;

    my $resource_gcis;
    for my $search_field (qw(doi print_issn online_issn url title other)) {
        if ($search_field ne 'other') {
           next unless $resource_info->{$search_field};
           $resource_gcis = find_item($gcis_handle, $gcis_type, $search_field, $resource_info->{$search_field});
           last if $resource_gcis;
        }
        for my $max_char (-1, 60, 40, 30) {
            my $id = make_identifier($resource_info->{title}, $max_char);
            $resource_gcis = $gcis_handle->get("/$gcis_type/$id");
            last if $resource_gcis;
        }
    }
    if (grep $gcis_type eq $_, qw(report journal article)) {
        my $id = $resource_gcis ? $resource_gcis->{identifier} :
                       make_identifier($resource_info->{title}, 60);
        $resource_info->{identifier} = $id;
        $resource_info->{uri} = "/$gcis_type/$id";
    }
    return $resource_gcis ? $resource_gcis : undef;
}

# TODO this doesn't seem to work logically. What does "fixing" a journal issn seek to do?

sub fix_jou_issn {
    my ($endnote_journal, $gcis_journal) = @_;

    my @issns = qw(print_issn online_issn);

    my $num_match = 0;
    my $num_endnote = 0;
    my $outer_issn_type;
    my $inner_issn_type;
    for my $issn_type (@issns) {
        next unless $endnote_journal->{$issn_type};
        $num_endnote++;
        for (@issns) {
            next unless $gcis_journal->{$_};
            next unless $endnote_journal->{$issn_type} eq $gcis_journal->{$_};
            $outer_issn_type = $issn_type;
            $inner_issn_type = $_;
            $num_match++;
        }
    }
    return 0 if $num_match < 1  ||  $num_match > 2;
    if ($num_endnote < 2) {
        $endnote_journal->{$_} = $gcis_journal->{$_} for @issns;
        return 1;
    }
    if ($num_match > 1) {
        return 0 if $endnote_journal->{print_issn} eq $endnote_journal->{online_issn};
        return 0 if $gcis_journal->{print_issn} eq $gcis_journal->{online_issn};
        $endnote_journal->{$_} = $gcis_journal->{$_} for @issns;
        return 1;
    }
    return 0 if $outer_issn_type eq $inner_issn_type;

    my $s = $endnote_journal->{$outer_issn_type};
    $endnote_journal->{$outer_issn_type} = $endnote_journal->{$inner_issn_type};
    $endnote_journal->{$inner_issn_type} = $s;
    return 1;
}

# Given two distinct completing ISSN (endnote and gcis), on bibs and
# the journal's issn, set the endnote bib issn to the gcis ISSN when
# the Journal has that issn

sub fix_bib_issn {
    my ($endnote_attrs, $gcis_attrs, $endnote_journal) = @_; 

    return 0 unless $endnote_attrs->{ISSN};
    return 0 unless $gcis_attrs->{ISSN};
    return 0 if $endnote_attrs->{ISSN} eq $gcis_attrs->{ISSN};

    my @valid_issns;
    push @valid_issns, $endnote_journal->{online_issn} if $endnote_journal->{online_issn};
    push @valid_issns, $endnote_journal->{print_issn} if $endnote_journal->{print_issn};
    return 0 unless @valid_issns > 1;
    for (@valid_issns) {
        next unless $gcis_attrs->{ISSN};
        next unless $_ eq $gcis_attrs->{ISSN};
        $endnote_attrs->{ISSN} = $gcis_attrs->{ISSN};
        return 1;
    }
    return 0;
}

# Given the errata and the article
# correct the articles DOI

sub fix_doi {
    my ($errata, $article) = @_;

    $article->{doi} or return 0;
    my $temp->{doi} = $article->{doi};
    $temp->{uri} = "/article/$article->{doi}";
    $errata->fix_errata($temp);
    $article->{doi} = $temp->{doi};
    return 1;
}

# Given the alternate_ids and the article,
# fidn the article_id for this article and
# set the alternate id key name to the value

sub fix_alt_id {
     my ($alternate_ids, $article) = @_;
     return 0 unless $article->{url};
     my $url = $article->{url};
     return 1 unless $alternate_ids->{$url};
     my ($alt_id_name, $alt_id_valie) = split '-', $alternate_ids->{$url};
     return 0 unless $alt_id_name && $alt_id_valie;
     $article->{$alt_id_name} = $alt_id_valie;
     return 1;
}

# Given a resource's endnote ref, map the endnote
# fields onto gcis fields.

sub map_attrs {
    my ($ref_handler, $attrs) = @_;

    for my $key (keys %BIB_MULTI) {
        next unless $ref_handler->{$key};
        if ($key =~ /author/) {
           ($_ =~ s/,$//) for @{ $ref_handler->{$key} };
        }
        my $s = xml_unescape(join '; ', @{ $ref_handler->{$key} }) or next;
        $attrs->{$BIB_MULTI{$key}} = $s;
    }

    for (keys %BIB_MAP) {
        next unless $ref_handler->{$_};
        $attrs->{$BIB_MAP{$_}} = $ref_handler->{$_}[0];
    }

    return 1 unless $attrs->{Notes};
    for ($attrs->{Notes}) {
       $_ or next;
       /^ *Ch\d+/ or next;
       s/^ *//;
       s/ *$//;
       $attrs->{_chapter} = $_;
       delete $attrs->{Notes} if $_ =~ /^ *Ch\d+ *$/;
    }

    return 1;
}

sub import_article {
    my $import_args = shift;

    my $gcis_handle = $import_args->{gcis};
    my $errata      = $import_args->{errata};
    my $ref_handler = $import_args->{ref};
    my $article;

    say " ---";
    $STATS{n_article}++;

    # Pull article information out of the EndNote reference
    # To build the Article Resource
    $article->{title} = xml_unescape(join ' ', @{ $ref_handler->{title} }) or do {
        say " ERROR: no title! : $ref_handler->{record_number}[0] : $ref_handler->{ref_key}[0]";
        $STATS{no_title}++;
        return 0;
    };
    for ($article->{title}) {
        s/\(\s+/\(/g;  s/\s+\)/\)/g;
    }

    my $article_key_map = {
        urls   => 'url',
        doi    => 'doi', 
        year   => 'year',
        volume => 'journal_vol',
        pages  => 'journal_pages',
    };
    for (keys %{ $article_key_map }) {
        next unless $ref_handler->{$_};
        $article->{$article_key_map->{$_}} = $ref_handler->{$_}[0];
    }
    $article->{author} = xml_unescape(join '; ', @{ $ref_handler->{author} });

    # break out any Key-Value pairs noted as alternate ids
    fix_alt_id($import_args->{alt_ids}, \%{ $article });

    # Clean up our External Identifiers
    if ($article->{doi}) {
        fix_doi($errata, $article);
    } elsif (!$article->{pmid}) {
        $article->{pmid} = PubMed::alt_id($article->{url}, $ref_handler->{pages}[0]) or do
        {
            say " WARN: no doi or alternate id : $article->{title} : $ref_handler->{record_number}[0] : $ref_handler->{ref_key}[0]";
            $STATS{no_doi_or_alternate_id}++;
        };
    }

    # Load external versions of the article, if they exist
    my $external_article;
    my $check_external = 0;
    if ($article->{doi}) {
        my $crossref_handle = CrossRef->new;
        $external_article = $crossref_handle->get($article->{doi});
        if (!$external_article) {
            say " WARN: doi not in crossref : $article->{doi} : $ref_handler->{record_number}[0] : $ref_handler->{ref_key}[0]";
            $STATS{doi_not_in_crossref}++;
       } else {
            $check_external = 1;
            $article->{identifier} = $article->{doi};
       }
    } elsif ($article->{pmid}) {
       my $pubMed_handle = PubMed->new;
       $external_article = $pubMed_handle->get($article->{pmid}); 
       if (!$external_article) {
           say " WARN: id not in pubmed : $article->{pmid}\n   for : $article->{title} : $ref_handler->{record_number}[0] : $ref_handler->{ref_key}[0]";
           $STATS{id_not_in_pubmed}++;
       } else {
           $check_external = 1;
           $article->{identifier} = 'pmid-'.$external_article->{pmid};
           $article->{pmid} = $external_article->{pmid};
       }
    }
    # Fallback on the GCIS version of the article
    if (!$external_article) {
       $external_article = get_item($gcis_handle, 'article', $article);
    }

    $article->{uri} = "/article/$article->{identifier}";

    # Build the Journal Resource
    my $journal;
    $journal->{title} = xml_unescape($ref_handler->{secondary_title}[0]) or do {
        say " ERROR: no journal title : $article->{identifier} : $ref_handler->{record_number}[0] : $ref_handler->{ref_key}[0]";
        $STATS{no_journal_title}++;
        return 0;
    };

    $journal->{print_issn} = $external_article->{issn}[0];
    $journal->{online_issn} = $external_article->{issn}[1];
    $journal->{publisher} = $external_article->{publisher};

    # Pull any matching existing GCIS Journal
    my $journalGCIS = get_item($gcis_handle, 'journal', $journal);

    # Apply errata? TODO 
    $errata->fix_errata($journal);

    say " jou :\n".Dumper($journal) if $verbose;

    # Ensure we have some identifier for the Journal
    if (!$journalGCIS) {
        if (!$journal->{print_issn}  &&  !$journal->{online_issn}) {
            say " ERROR: no journal issn : $journal->{uri} : $ref_handler->{record_number}[0] : $ref_handler->{ref_key}[0]";
            $STATS{no_journal_issn}++;
            return 0;
        }
    }

    # Try to Update or Add the journalling, handling Diffs as needed
    if ($journalGCIS) {
        fix_jou_issn($journal, $journalGCIS);
        my $ignored = $errata->diff_okay($journal);
        my $DIFF = compare_hash($journal, $journalGCIS, $ignored);
        if ($DIFF) {
            say " NOTE: existing journal different : $journal->{uri}";
            $STATS{existing_journal_different}++;
            if (can_fix_item($DIFF)  &&  $do_fix_items) {
                say " NOTE: can fix journal : $journalGCIS->{uri}";
                $STATS{"can_fix_journal"}++;
                fix_item($journal, $journalGCIS, $ignored);
                my $fixed_diff = compare_hash($journal, $journalGCIS, $ignored);
                !$fixed_diff or die "didn't fix journal!";
                update_item($gcis_handle, $journalGCIS);
                $journal->{uri} = $journalGCIS->{uri};
            } else {
                $DIFF{$journal->{uri}} = $DIFF;
                return 0;
            }
        } else {
            say " NOTE: existing journal same : $journal->{uri}";
            $STATS{existing_journal_same}++;
        }
    } elsif (!$do_not_add_journals) {
        add_item($gcis_handle, $journal) or return 0;
    } else {
        return 0;
    }

    # Back to Article handling - set journal on article and fix errata TODO
    $article->{journal_identifier} = $journal->{identifier};
    $errata->fix_errata($article);

    say " art :\n".Dumper($article) if $verbose;

    # Assert the article matches the external
    if ($check_external) {
        my $ignored = $errata->diff_okay($article);
        $ignored->{$_} = 1 for qw(uri identifier journal_identifier url);
        my $DIFF = compare_hash($article, $external_article, $ignored);
        if ($DIFF) {
            $DIFF{$article->{uri}} = $DIFF;
            say " NOTE: external source article different : $article->{uri}";
            $STATS{external_source_article_different}++;
           return 0;
        }
    }

    # Handle Updating or Adding the article
    my $articleGCIS = $gcis_handle->get($article->{uri});
    if ($articleGCIS) {
        my $ignored = $errata->diff_okay($article);
        $ignored->{$_} = 1 for qw(uri author pmid);
        my $DIFF = compare_hash($article, $articleGCIS, $ignored);
        if ($DIFF) {
            say " NOTE: existing article different : $article->{uri}";
            $STATS{existing_article_different}++;
            return 0;
            if (can_fix_item($DIFF)  &&  $do_fix_items) {
                say " NOTE: can fix article : $articleGCIS->{uri}";
                $STATS{"can_fix_article"}++;
                fix_item($article, $articleGCIS, $ignored);
                my $fixed_diff = compare_hash($article, $articleGCIS, $ignored);
                !$fixed_diff or die "didn't fix article!";
                update_item($gcis_handle, $articleGCIS);
                $article->{uri} = $articleGCIS->{uri};
            } else {
                $DIFF{$articleGCIS->{uri}} = $DIFF;
                return 0;
            }
        } else {
            say " NOTE: existing article same : $article->{uri}";
            $STATS{existing_article_same}++;
        }
    } elsif (!$do_not_add_items) {
       add_item($gcis_handle, $article) or return 0;
    } else {
       return 0;
    }

    # Creating the Reference
    my $article_reference;
    $article_reference->{identifier} = $ref_handler->{ref_key}[0];
    $article_reference->{uri} = "/reference/$article_reference->{identifier}";
    my $reference_attrs = \%{ $article_reference->{attrs} };

    # clean up the attr keys
    ## general key name mapping
    map_attrs($ref_handler, $reference_attrs);

    ## kill extraneous fields
    for ('Publication Title', 'Secondary Title', 'ISBN') {
        next unless $reference_attrs->{$_};
        delete $reference_attrs->{$_};
    }

    ## article-specific key name mapping
    my $extra_map = {
        'Date Published' => 'Date',
        'Publisher' => '.publisher',
    };
    for (keys %{ $extra_map }) {
        next unless $reference_attrs->{$_};
        $reference_attrs->{$extra_map->{$_}} = $reference_attrs->{$_};
        delete $reference_attrs->{$_};
    }

    # Overwrite these fields with the endnote values, but gcis keys
    my $article_field_map = {
        author        => 'Author', 
        title         => 'Title', 
        url           => 'URL',
        doi           => 'DOI',
        journal_pages => 'Pages', 
        journal_vol   => 'Volume',
        year          => 'Year', 
        pmid          => 'PMID', 
    };
    foreach my $endnote_key (keys %{ $article_field_map }) {
        my $gcis_key = $article_field_map->{$endnote_key};
        if (!defined $article->{$endnote_key}) {
            next unless $reference_attrs->{$gcis_key};
            delete $reference_attrs->{$gcis_key};
            next;
        }
        $reference_attrs->{$gcis_key} = $article->{$endnote_key};
    }

    # Add extra attrs and fix errata TODO
    $reference_attrs->{'.reference_type'} = 0;
    $reference_attrs->{ISSN} = $journal->{online_issn} ? $journal->{online_issn} : $journal->{print_issn};
    $reference_attrs->{Journal} = $journal->{title};

    $errata->fix_errata($article_reference);

    say " bib :\n".Dumper($article_reference) if $verbose;

    # Update or Add the reference
    # Handle the DIFF issues in the update
    my $existing_gcis_ref = $gcis_handle->get($article_reference->{uri});
    if ($existing_gcis_ref) {
        fix_bib_issn($reference_attrs, $existing_gcis_ref->{attrs}, $journal);
        my $ignored = $errata->diff_okay($article_reference);
        $ignored->{_record_number} = 1;
        my $difference = compare_hash($article_reference, $existing_gcis_ref, $ignored);
        if ($difference) {
            say " NOTE: existing reference different : $article_reference->{uri}";
            $STATS{existing_reference_different}++;
            if (can_fix_item($difference)  &&  $do_fix_items) {
                say " NOTE: can fix reference: $article_reference->{uri}";
                $STATS{"can_fix_reference"}++;
                fix_item($article_reference, $existing_gcis_ref, $ignored);
                my $fixed_diff = compare_hash($article_reference, $existing_gcis_ref, $ignored);
                !$fixed_diff or die "didn't fix reference!";
                update_item($gcis_handle, $existing_gcis_ref);
                return 0 if $do_not_add_references  ||
                            $existing_gcis_ref->{child_publication};
            } else {
                $DIFF{$article_reference->{uri}} = $difference;
                return 0;
            }
        } else {
            say " NOTE: existing reference same : $article_reference->{uri}";
            $STATS{existing_reference_same}++;
            return 0 if $do_not_add_references  ||  
                        $existing_gcis_ref->{child_publication};
        }
    } elsif (!$do_not_add_references) {
        add_item($gcis_handle, $article_reference) or return 0;
    } else {
        return 0;
    }

    # Connect the child publication
    $article_reference->{child_publication_uri} = $article->{uri};
    add_child_pub($gcis_handle, $article_reference) or return 0;

    return 1;
}

sub import_other {
    my $import_args = shift;

    my $gcis_handle = $import_args->{gcis};
    my $errata = $import_args->{errata};
    my $ref_handler = $import_args->{ref};
    my $type = $import_args->{type};
    my $resource;

    say " ---";
    $STATS{"n_$type"}++;

    # Pull information out of the EndNote reference
    # to build the Resource
    $resource->{title} = xml_unescape(join ' ', @{ $ref_handler->{title} }) or do {
        say " ERROR: no title! : $ref_handler->{record_number}[0] : $ref_handler->{ref_key}[0]";
        $STATS{no_title}++;
        return 0;
    };

    my $resource_key_map = {
        webpage => {
            urls => 'url', 
            year => 'access_date',
        }, 
        report => {
            urls => 'url', 
            doi  => 'doi', 
            year => 'publication_year',
            abstract => 'summary', 
        },
    };

    my $this_resource_key_map = $resource_key_map->{$type} or 
        die "unknown type : $type";
    for (keys %{ $this_resource_key_map }) {
        next unless $ref_handler->{$_};
        $resource->{$this_resource_key_map->{$_}} = $ref_handler->{$_}[0];
    }

    if ($type eq 'webpage'  &&  $resource->{access_date}) {
       delete $resource->{access_date} if $resource->{access_date} eq 'Undated';
       $resource->{access_date} .= "-01-01T00:00:00" if $resource->{access_date};
    }
    if ($type eq 'report'  &&  $resource->{publication_year}) {
       delete $resource->{publication_year} if $resource->{publication_year} eq 'n.d.';
    }

    $resource->{uri} = "/$type/".make_identifier($resource->{title});
    $errata->fix_errata($resource);

    # Try to load any existing version of resource from GCIS
    my $resource_in_gcis = get_item($gcis_handle, $type, $resource);

    # Apply any errata to the resource
    $errata->fix_errata($resource);

    say " item :\n".Dumper($resource) if $verbose;
    ## NOTE
    if ($resource_in_gcis) {
        my $ignored = $errata->diff_okay($resource);
        $ignored->{uri} = 1;
        my $res_diff = compare_hash($resource, $resource_in_gcis, $ignored);
        if ($res_diff) {
            say " NOTE: existing $type different : $resource_in_gcis->{uri}";
            $STATS{"existing_".$type."_different"}++;
            if (can_fix_item($res_diff)  &&  $do_fix_items) {
                say " NOTE: can fix $type : $resource_in_gcis->{uri}";
                $STATS{"can_fix_".$type}++;
                fix_item($resource, $resource_in_gcis, $ignored);
                my $fixed_diff = compare_hash($resource, $resource_in_gcis, $ignored);
                !$fixed_diff or die "didn't fix $type!"; 
                update_item($gcis_handle, $resource_in_gcis);
                $resource->{uri} = $resource_in_gcis->{uri};
            } else {
                $DIFF{$resource_in_gcis->{uri}} = $res_diff;
                return 0;
            }
        } else {
            say " NOTE: existing $type same : $resource_in_gcis->{uri}";
            $STATS{"existing_".$type."_same"}++;
            $resource->{uri} = $resource_in_gcis->{uri};
        }
    } elsif (!$do_not_add_items) {
        $a->{uri} = add_item($gcis_handle, $a) or return 0;
    } else {
       return 0;
    }

    my $resource_reference;
    $resource_reference->{identifier} = $ref_handler->{ref_key}[0];
    $resource_reference->{uri} = "/reference/$resource_reference->{identifier}";
    my $reference_attrs = \%{ $resource_reference->{attrs} };

    map_attrs($ref_handler, $reference_attrs);

    $reference_attrs->{Title} = $resource->{title};

    # Overwrite these fields with the EndNote value, but use the GCIS key.
    my $all_field_map = {
        webpage => {
            url => 'URL',
            access_date => 'Year',
        },
        report => {
            url => 'URL',
            doi  => 'DOI',
            publication_year => 'Year',
            summary => 'abstract',
        },
    };

    my $thisType_field_map = $all_field_map->{$type};
    foreach my $endnote_key ( keys %{ $thisType_field_map }) {
        my $gcis_key = $thisType_field_map->{$endnote_key};
        if (!defined $resource->{$endnote_key}) {
            next unless defined $reference_attrs->{$gcis_key};
            delete $reference_attrs->{$gcis_key};
            next;
        }
        $reference_attrs->{$gcis_key} = $resource->{$endnote_key};
    }

    # handle extra attributes munging and fix errate (TODO what?)
    if (defined $reference_attrs->{Issue}) {
         $reference_attrs->{Number} = $reference_attrs->{Issue};
         delete $reference_attrs->{Issue};
    }
    if ($type eq 'webpage'  &&  $reference_attrs->{Year}) {
        $reference_attrs->{Year} =~ s/^(\d{4}).*/$1/;
    }
    $reference_attrs->{'.reference_type'} = $REF_TYPE_NUM{$type};

    $errata->fix_errata($resource_reference);

    say " bib :\n".Dumper($resource_reference) if $verbose;

    my $existing_gcis_ref = $gcis_handle->get($resource_reference->{uri});
    if ($existing_gcis_ref) {
        my $ignored = $errata->diff_okay($resource_reference);
        $ignored->{_record_number} = 1;
        my $difference = compare_hash($resource_reference, $existing_gcis_ref, $ignored);
        if ($difference) {
            say " NOTE: existing reference different : $resource_reference->{uri}";
            $STATS{existing_reference_different}++;
            if (can_fix_item($difference)  &&  $do_fix_items) {
                say " NOTE: can fix reference: $resource_reference->{uri}";
                $STATS{"can_fix_reference"}++;
                fix_item($resource_reference, $existing_gcis_ref, $ignored);
                my $fixed_diff = compare_hash($resource_reference, $existing_gcis_ref, $ignored);
                !$fixed_diff or die "didn't fix reference!";
                update_item($gcis_handle, $existing_gcis_ref);
                return 0 if $do_not_add_references  ||  
                            $existing_gcis_ref->{child_publication};
            } else {
                $DIFF{$resource_reference->{uri}} = $difference;
                return 0;
            }
        } else {
            say " NOTE: existing reference same : $resource_reference->{uri}";
            $STATS{existing_reference_same}++;
            return 0 if $do_not_add_references  ||  
                        $existing_gcis_ref->{child_publication};
        }
    } elsif (!$do_not_add_references) {
        add_item($gcis_handle, $resource_reference) or return 0;
    } else {
        return 0;
    }

    $resource_reference->{child_publication_uri} = $resource->{uri};
    add_child_pub($gcis_handle, $resource_reference) or return 0;

    return 1;
}

sub assign_bib_keys_gcis_names {
    my ( $bib_attrs, $type ) = @_;

    my $bib_key_map = $BIB_TYPE_KEY_MAP->{$type};
    foreach my $endnote_bib_key (keys %{ $bib_key_map }) {
        # If the EN key has no GCIS equivalent, kill it from the attrs
        if ( ! defined $bib_key_map->{$endnote_bib_key} ) {
            next if !defined $bib_attrs->{$endnote_bib_key};
            delete $bib_attrs->{$endnote_bib_key};
            next;
        }
        # If we don't have a value in the attrs for the EN key,
        # but have something in attrs for the gcis equivalent key,
        # delete that gcis key from attrs
        my $gcis_bib_key = $bib_key_map->{$endnote_bib_key};
        if (
             ! defined $bib_attrs->{$endnote_bib_key}
        ) {
            next if !defined $bib_attrs->{$gcis_bib_key};
            delete $bib_attrs->{$gcis_bib_key};
            next;
        }
        # Set the attrs gcis key to the value of the attrs EN key
        # delete the EN key
        $bib_attrs->{$gcis_bib_key} = $bib_attrs->{$endnote_bib_key};
        delete $bib_attrs->{$endnote_bib_key};
    }

    return $bib_attrs;
}

sub massage_bib_attrs {
    my ( $ref_handler, $type ) = @_;

    my $bib_attrs->{Title} = xml_unescape(join ' ', @{ $ref_handler->{title} }) or do {
        say " ERROR: no title! : $ref_handler->{record_number}[0]"
            . " : $ref_handler->{ref_key}[0]";
        $STATS{no_title}++;
        return 0;
    };
    map_attrs($ref_handler, $bib_attrs);
    $bib_attrs = assign_bib_keys_gcis_names( $bib_attrs, $type );
    $bib_attrs->{'.reference_type'} = $REF_TYPE_NUM{$type};

    return $bib_attrs;
}

# TODO
# TODO break this up with aggression

sub create_bib_data {
    my $import_args = shift;
    my $gcis_handle = $import_args->{gcis};
    my $errata = $import_args->{errata};
    my $ref_handler = $import_args->{ref};
    my $type = $import_args->{type};

    say " ---";
    $STATS{"n_$type"}++;

    my $bib;
    $bib->{identifier} = $ref_handler->{ref_key}[0];
    $bib->{uri} = "/reference/$bib->{identifier}";

    $bib->{attrs} = massage_bib_attrs( $ref_handler, $type );

    $errata->fix_errata($bib);

    say " bib :\n".Dumper($bib) if $verbose;

    return $bib;
}

sub update_existing_bib {
    my ($import_args, $bib_existing) = shift;
    my $gcis_handle = $import_args->{gcis};
    my $errata      = $import_args->{errata};
    my $bib         = $import_args->{bib};

    my $resource_uri = $bib_existing->{uri};
    my ($resource_path) = ($resource_uri =~ /^\/(.*?)\//);

    if ($dry_run) {
        say " would update $resource_path : $resource_uri";
        $N_UPDATES++;
        $STATS{"would_update_$resource_path"}++;
        return 1;
    }

    my $ignored = $errata->diff_okay($bib);
    $ignored->{_record_number} = 1;
    my $difference = compare_hash($bib, $bib_existing, $ignored);
    if ($difference) {
        say " NOTE: existing reference different : $bib->{uri}";
        $STATS{existing_reference_different}++;
        if (can_fix_item($difference)  &&  $do_fix_items) {
            say " NOTE: can fix reference: $bib->{uri}";
            $STATS{"can_fix_reference"}++;
            fix_item($bib, $bib_existing, $ignored);
            my $fixed_diff = compare_hash($bib, $bib_existing, $ignored);
            !$fixed_diff or die "didn't fix reference!";
            update_item($gcis_handle, $bib_existing);
        } else {
            $DIFF{$bib->{uri}} = $difference;
            return 0;
        }
    } else {
        say " NOTE: existing reference same : $bib->{uri}";
        $STATS{existing_reference_same}++;
    }
    return;
}

sub import_bib {
    my $import_args = shift;
    my $gcis_handle = $import_args->{gcis};
    my $bib         = $import_args->{bib};

    my $bib_existing = $gcis_handle->get($bib->{uri});
    if ($bib_existing) {
        update_existing_bib($import_args, $bib_existing);
    } elsif (!$do_not_add_references) {
        add_item($gcis_handle, $bib);
    }

    return $bib;
}

# Utility Function to format the DIFF...
# TODO why?

sub format_diff {
    my ($k, $d) = @_;
    my $e;
    if (!grep '_A_' eq $_, keys %{ $d }) {
        for (sort keys %{ $d }) {
            push @{ $e->{$k} }, format_diff($_, $d->{$_});
        }
        return $e;
    }
    $e->{item} = $k;
    $e->{value} = $d->{_B_};
    $e->{alias} = $d->{_A_};
    return $e;
}

# Utility Function Given a DIFF filename, dump the DIFF out to it

sub dump_diff {

    my $n_diff = keys %DIFF;
    return 1 if $n_diff == 0  ||  !$diff_file;

    my $y;
    for my $k (sort keys %DIFF) {
        my $v;
        $v->{uri} = $k;
        for (sort keys %{ $DIFF{$k} }) {
            my $d = $DIFF{$k}->{$_};
            push @{ $v->{errata} }, format_diff($_, $d);
        }
        push @{ $y }, $v;
    }

    open my $f, '>:encoding(UTF-8)', $diff_file or die "can't open DIFF file";
    say $f Dump($y);
    close $f;

    return 1;
}

# Utility Function Given a file containing alternate IDs, load the YAML file into perl

sub load_alt_ids {
    return undef unless $alt_id_file;
    open my $file_handle, '<:encoding(UTF-8)', $alt_id_file or 
       die "can't open alternate id file";
    my $yml = do { local $/; <$file_handle> };
    close $file_handle;

    my $yaml_content = Load($yml);
    my $alt_id;
    for (@{ $yaml_content }) {
       my $key = $_->{url} or next;
       $alt_id->{$key} = $_->{id} or next;
    }
    return $alt_id ? $alt_id : undef;
}

# Prints out our initial refs info

sub report_initial_state {
    my ($n) = @_;

    # Report Options Settings
    say " importing endnote references";
    say "   url : $url";
    say "   endnote_file : $endnote_file";
    say "   max_updates : $max_updates";
    say "   max_references : $max_references";
    say "   do_not_add_journals" if $do_not_add_journals;
    say "   do_not_add_items" if $do_not_add_items;
    say "   do_not_add_referneces" if $do_not_add_references;
    say "   errata_file : $errata_file" if $errata_file;
    say "   diff_file : $diff_file" if $diff_file;
    say "   alt_id_file : $alt_id_file" if $alt_id_file;
    say "   verbose" if $verbose;
    say "   dry_run" if $dry_run;
    say '';

    # Report Type Counts
    say " endnote entries : ";
    my $n_tot = 0;
    for (keys %{ $n }) {
        say "   $_ : $n->{$_}";
        $n_tot += $n->{$_};
    }
    say "   total : $n_tot\n";

    return;
}

sub report_final_state {

    my $n_diff = keys %DIFF;
    say "\n n DIFF : $n_diff";

    my $n_stat = 0;
    for (sort keys %STATS) {
        say "   $_ : $STATS{$_}";
        $n_stat += $STATS{$_};
    }
    say " n stat : $n_stat";

    return;
}

sub main {
    my %import_args;
    $import_args{gcis} = $dry_run ? Gcis::Client->new(url => $url)
                        : Gcis::Client->connect(url => $url);
    $import_args{errata} = Errata->load($errata_file);

    my $ref_handler = Refs->new;
    $ref_handler->{n_max} = $max_references;
    $ref_handler->load($endnote_file);
    $import_args{alt_ids} = load_alt_ids($alt_id_file);

    # Internal config switches
    my $bib_only = 0;
    my $do_all_types = 1;

    report_initial_state($ref_handler->type_counts);

    my %types_to_process = (
        article => 1,
        report  => 1,
        webpage => 1,
    );
    foreach my $record (@{ $ref_handler->{records} }) {
        $import_args{ref} = $record;
        $import_args{type} = $TYPE_MAP{$record->{reftype}[0]} or
            die " type not known : $record->{reftype}[0]";

        # Create bib entry
        $import_args{bib} = create_bib_data( \%import_args );
        import_bib( \%import_args );

        if ( ! $bib_only ) {
            # TODO these should be cleaned up and redundant code refactored
            if ( $import_args{type} = 'article' ) {
            }
            if ( $import_args{type} = 'book' ) {
            }
            elsif ( $types_to_process{ $import_args{type} } ){
                # Create pub entry
                # import pub (create/update)
            }
            else {
                # Not a type we can create
                # report out?
            }
        }
        #elsif ($import_args{type} eq 'article'  &&  !$bib_only) {
        #    import_article(\%import_args);
        #} elsif ((grep $import_args{type} eq $record, qw(webpage report))  && !$bib_only) {
        #    import_other(\%import_args);
        #}

        last if $max_updates > 0  &&  $N_UPDATES >= $max_updates;
    }

    dump_diff;
    report_final_state;

    return;
}
