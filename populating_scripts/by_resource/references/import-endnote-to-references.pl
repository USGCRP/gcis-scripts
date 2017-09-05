#!/usr/bin/env perl

=head1 NAME

import-endnote-to-references.pl -- Import an EndNote xml dump to GCIS References

=head1 DESCRIPTION

import-endnote-to-references.pl imports bibliographical entries to a GCIS instance from an
xml dump of an EndNote file.  The biblio entry is checked aganist existing
information in GCIS before import.

This program does not link to the reference to a report, this needs to be done
seperately. The output document *_references_created.csv can be used later to
connect them.

If there reference already exists and differs, the differences are put into
the differences yml file.

If a matching entry already exists in GCIS, the new entry is not added.

An errata file may be used to ignore differences between the GCIS
entry and the EndNote file.  This allows for the new entry obtained from 
EndNote to be different from the information stored in GCIS (the GCIS 
information is not changed). The diff can be fed back in for this purpose.

=head1 SYNOPSIS

./import-endnote-to-references.pl [OPTIONS]

=head1 OPTIONS

=over

=item B<--url>

GCIS url to work against, e.g. http://data-stage.globalchange.gov

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

=item B<--wait>

Time to wait between GCIS updates (seconds; defaults to -1 - do not wait)

=item B<--errata_file>

Errata file (yaml) - contains endnote aliases for entries that
already exists (see below for file example)

=item B<--diff_file>

Difference file (yaml) - will contain differences between the new
entry and an existing GCIS entry

=item B<--references_file>

References file (csv) - will contain the URIs for each reference
processed - be they created, differing, or preexisting.

=item B<--uuid_generation>

If the EndNote is missing UUIDs, go ahead and generate them. For the moment,
this should only be used for test runs. Find UUID generation belongs to TSU.

=item B<--verbose>

Verbose option

=item B<--dry_run> or B<--n>

Dry run option

=back

=head1 EXAMPLES

# add a set of references to GCIS from an endnote file:

./import-endnote-to-references.pl -u http://data-stage.globalchange.gov 
                    -e endnote.xml

Example errata file (value corresponds to GCIS, alias to input):

---
article:
- uri: /reference/one-with-an-issue
  errata:
  - item: print_issn

Items in the difference file can be converted to errata items, 
but each item should be carefully considered.

=cut

use lib './lib';

use Data::Dumper;
use Gcis::Client;
use Refs;
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
    'wait=i'                => \(my $wait = -1),
    'errata_file=s'         => \(my $errata_file),
    'diff_file=s'           => \(my $diff_file),
    'references_file=s'     => \(my $references_file),
    'verbose'               => \(my $verbose),
    'dry_run|n'             => \(my $dry_run),
    'uuid_generation'       => \(my $uuid_gen),
    'help|?'                => sub { pod2usage(verbose => 2) },
) or die pod2usage(verbose => 1);

pod2usage(msg => "missing url or endnote file", verbose => 1) unless ($url && $endnote_file);

## Data Maps

my %TYPE_MAP = (
   'Book'                     => 'book',
   'Edited Book'              => 'edited_book',
   'Electronic Book'          => 'book',
   'Book Section'             => 'book_section', 
   'Electronic Book Section'  => 'book_section',
   'Report'                   => 'report',
   'Manuscript'               => 'report',
   'Journal Article'          => 'article',
   'Electronic Article'       => 'generic_article',
   'Web Page'                 => 'webpage',
   'Dataset'                  => 'dataset',
   'Conference Paper'         => 'generic_cpaper', 
   'Online Multimedia'        => 'generic_media',
   'Legal Rule or Regulation' => 'generic_legal', 
   'Press Release'            => 'generic_press', 
   'Aggregated Database'      => 'generic_aggregateDB',
);

my $BIB_TYPE_KEY_MAP = {
    article        => {
        'Date Published'    => 'Date',
        'Publisher'         => '.publisher',
        'Publication Title' => undef,
        'Secondary Title'   => 'Journal', 
        'ISBN'              => undef, 
    },
    edited_book    => {
        'Issue'             => 'Edition',
        'Pages'             => 'Number of Pages',
        'Author'            => 'Editor',
    },
    book           => {
        'Issue'             => 'Edition', 
        'Pages'             => 'Number of Pages',
        'Secondary Author'  => 'Editor', 
    },
    book_section   => {
        'Secondary Title'   => 'Book Title', 
        'Issue'             => 'Edition',
        'Secondary Author'  => 'Editor',
    },
    generic_legal  => { },
    generic_press  => { },
    generic_media  => {
        'Secondary Title'   => 'Periodical Title', 
        'Date'              => 'E-Pub Date', 
    },
    generic_cpaper => {
        'Place Published'   => 'Conference Location', 
        'Secondary Title'   => 'Conference Name', 
        'Year'              => 'Year of Conference',
    },
    report         => {
        'Issue'             => 'Number', 
    },
    webpage        => {
        'Issue'             => 'Number', 
    },
};

my %REF_TYPE_NUM = (
   article         => 0,
   book_section    => 7,
   book            => 9,
   edited_book     => 9,
   report          => 10,
   generic_legal   => 32,
   generic_cpaper  => 47,
   generic_media   => 48,
   generic_press   => 63,
   webpage         => 16,
);

my %DIFF;
my %REFS;
my $N_UPDATES = 0;
my %STATS;

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

# Utility Function to compare two hashes and return a DIFF set

sub compare_hash {
    my ($endnote_sourced_hash, $existing_hash, $ignore) = @_;

    my %hash_result;
    for (keys %{ $endnote_sourced_hash }) {

        # SKIP - ignored field
        next if $ignore->{$_};

        # SKIP - neither new nor existing reference are defined  (TODO is this possible...?)
        next if !defined $endnote_sourced_hash->{$_}  &&  !defined $existing_hash->{$_};

        # DIFF - exists in New but not Existing
        if (!defined $existing_hash->{$_}) {
           $hash_result{$_} = {_A_ => $endnote_sourced_hash->{$_}, _B_ => undef};
           next;
        }
        # DIFF - exists in Existing but not New
        if (!defined $endnote_sourced_hash->{$_}) {
           $hash_result{$_} = {_A_ => undef, _B_ => $existing_hash->{$_}};
           next;
        }

        # RECURSE - compare sub hashes
        if (ref $endnote_sourced_hash->{$_} eq 'HASH') {
            my $hash_c1 = compare_hash($endnote_sourced_hash->{$_}, $existing_hash->{$_}, $ignore) or next;
            $hash_result{$_} = $hash_c1;
            next;
        }

        # SKIP - values are the same
        next if $endnote_sourced_hash->{$_} eq $existing_hash->{$_};

        # CLEAN - remove xml chaff
        my $endnote_entry = lc xml_unescape($endnote_sourced_hash->{$_});
        my $existing_entry = lc xml_unescape($existing_hash->{$_});

        # CLEAN - remove misc
        for ($endnote_entry, $existing_entry) {
            s/^\s+//; s/\s+$//; # CLEAN - clean leading and trails whitespace.
            s/\.$//;            # CLEAN - Kill trailing periods.
            s/\r/; /g;          # CLEAN - Replace returns with '; '
        }

        # SKIP - values are the same
        next if $endnote_entry eq $existing_entry;

        # SKIP - authors are equivalent
        if (lc $_ eq 'author') {
            next if compare_authors(lc $endnote_entry, lc $existing_entry);
        }

        # DIFF - values differ
        $hash_result{$_} = {_A_ => $endnote_sourced_hash->{$_}, _B_ => $existing_hash->{$_}};
    }

    return %hash_result ? \%hash_result : undef;
}

# Utility Function to compare if two author lists are the same

sub compare_authors {
    my ($endnote_author_list, $existing_author_list) = @_;
    my @endnote_authors = split '; ', $endnote_author_list;
    my @existing_authors = split '; ', $existing_author_list;

    for my $endnote_author (@endnote_authors) {
        my $existing_author = shift @existing_authors;     # Holds 'Last, First M.'

        # Mismatch in number of authors.
        return 0 unless $existing_author;

        # easy case
        if ( $existing_author eq $endnote_author ) {
            next;
        }

        my ($existing_author_last, $existing_author_first) = split (', ', $existing_author);
        next if compare_author($endnote_author, $existing_author_first, $existing_author_last);

        # No Match on either
        return 0;
    }
    return 1;
}

# Utility Function to compare if two authors are the same
# We care if the last name and first initial are the same
# We can ignore ", jr", ", II", and ", III". We always ignore middle initials
# We can handle the formats First M. Last and Last, First M.
# We ignore punctuation characters.
# This occasionally still pops up a false positive, but they should be minimal

sub compare_author {
    my ($endnote_author, $author_first, $author_last) = @_;

    # Clean out generational marker
    $endnote_author =~ s/", jr"//;
    $endnote_author =~ s/", ii"//i;
    $endnote_author =~ s/", iii"//i;

    my ($endnote_first, $endnote_last);
    if ( $endnote_author !~ /,/ ) { 
    # Handle the First M. Last format
       $endnote_author =~ s/[[:punct:]]//g;
       ($endnote_first, $endnote_last) = $endnote_author =~ /^(.*) (\w+)$/g;
    } else {
    # Handle the Last, First M. format
       ($endnote_last, $endnote_first) = $endnote_author =~ /^([ \w]+), (.*)$/g;
       $endnote_last =~ s/[[:punct:]]//g;
       $endnote_first =~ s/[[:punct:]]//g;
    }

    # fail if last names don't match
    return 0 if $author_last ne $endnote_last;
    # move on if no first name
    return 1 if !$author_first && !$endnote_first;
    # Fail if one has a first but the other doesn't
    return 0 if $author_first && !$endnote_first;
    # Fail if the other one has a first but the other doesn't
    return 0 if !$author_first && $endnote_first;
    # Fail if the first initials don't match
    return 0 if substr($author_first, 0, 1) ne substr($endnote_first, 0, 1);

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

sub convert_bib_attrs {
    my ( $endnote_record, $type ) = @_;

    my $gcis_ref_attrs->{Title} = xml_unescape(join ' ', @{ $endnote_record->{title} }) or do {
        say " ERROR: no title! : $endnote_record->{record_number}[0]"
            . " : $endnote_record->{ref_key}[0]";
        $STATS{no_title}++;
        return 0;
    };

    # For keys that have multiple entries in endote
    # group them together and store under the GCIS key
    my %bib_multi = (
        author           => 'Author',
        keywords         => 'Keywords',
        secondary_author => 'Secondary Author',
        secondary_title  => 'Secondary Title',
        pub_title        => 'Publication Title', 
    );
    for my $key (keys %bib_multi) {
    # TODO parse out clearer
        next unless $endnote_record->{$key};
        if ($key =~ /author/) {
           ($_ =~ s/,$//) for @{ $endnote_record->{$key} };
        }
        my $s = xml_unescape(join '; ', @{ $endnote_record->{$key} }) or next;
        $gcis_ref_attrs->{$bib_multi{$key}} = $s;
    }

    # For keys that have a single entry in endnote
    # store under the GCIS key
    my %bib_map = (
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
    for (keys %bib_map) {
        next unless $endnote_record->{$_};
        $gcis_ref_attrs->{$bib_map{$_}} = $endnote_record->{$_}[0];
    }

    # TODO parse out clearer

    if ( $gcis_ref_attrs->{Notes} ) {
        for ( $gcis_ref_attrs->{Notes} ) { # is this a look just on one item?
             $_ or next;
             /^ *Ch\d+/ or next;
             s/^ *//;
             s/ *$//;
             $gcis_ref_attrs->{_chapter} = $_;
             delete $gcis_ref_attrs->{Notes} if $_ =~ /^ *Ch\d+ *$/;
        }
    }

    # Convery key names based on type
    $gcis_ref_attrs = assign_bib_keys_gcis_names( $gcis_ref_attrs, $type );

    $gcis_ref_attrs->{'.reference_type'} = $REF_TYPE_NUM{$type};

    return $gcis_ref_attrs;
}

sub get_gcis_identifier {
    my ($endnote_record, $gcis) = @_;

    my $identifier = $endnote_record->{ref_key}[0];
    return $identifier if $identifier;

    if ( $uuid_gen ) {
        # no identifier found? generate one.
        $identifier = $gcis->get('/uuid');
        say "No EndNote UUID found; generated: $identifier->[0]";
        return $identifier->[0] if $identifier->[0];
    }
    else {
        warn Dumper $endnote_record;
        exit "EndNote Entry missing UUID!";
    }
}

sub create_bib_data {
    my %import_args = @_;
    my $gcis_handle    = $import_args{gcis_handle};
    my $errata         = $import_args{errata};
    my $endnote_record = $import_args{endnote_record};
    my $type           = $import_args{type};

    say " ---";
    $STATS{"n_$type"}++;

    my $gcis_reference;
    #$gcis_reference->{identifier} = $endnote_record->{ref_key}[0];
    $gcis_reference->{identifier} = get_gcis_identifier($endnote_record, $gcis_handle);
    $gcis_reference->{uri} = "/reference/$gcis_reference->{identifier}";

    $gcis_reference->{attrs} = convert_bib_attrs( $endnote_record, $type );

    # Overwrite any meh data from the import with our provided
    # errata.
    $errata->fix_errata($gcis_reference);

    say " gcis_reference :\n".Dumper($gcis_reference) if $verbose;

    return $gcis_reference;
}

sub check_existing_bib {
    my (%import_args) = @_;
    my $gcis_handle       = $import_args{gcis_handle};
    my $errata            = $import_args{errata};
    my $new_ref_data      = $import_args{reference_data};
    my $gcis_ref_existing = $import_args{existing};

    my $resource_uri = $new_ref_data->{uri};
    my ($resource_path) = ($resource_uri =~ /^\/(.*?)\//);

    my $ignored = $errata->diff_okay($new_ref_data);
    $ignored->{_record_number} = 1;
    my $difference_hash = compare_hash($new_ref_data, $gcis_ref_existing, $ignored);
    if ($difference_hash) {
        say " NOTE: existing reference different : $new_ref_data->{uri}";
        $STATS{existing_reference_different}++;
        $REFS{$resource_uri}{'gcis_state'} = "found - differing";
        add_to_diff($new_ref_data->{uri}, $difference_hash);
        return 0;
    } else {
        say " NOTE: existing reference same : $new_ref_data->{uri}";
        $REFS{$resource_uri}{'gcis_state'} = "found - same/errata'd";
        $STATS{existing_reference_same}++;
    }
    return;
}

sub import_reference {
    my %import_args = @_;
    my $gcis_handle    = $import_args{gcis_handle};
    my $errata         = $import_args{errata};
    my $endnote_record = $import_args{endnote_record};
    my $type           = $import_args{type};
    my $reference_data = $import_args{reference_data};

    $REFS{$reference_data->{uri}} = {
        UUID          => $reference_data->{identifier},
        action        => 'create_reference',
        endnote_type  => $endnote_record->{reftype}[0],
        gcis_type     => $type,
        gcis_state    => '',
        gcis_resource => $reference_data->{uri},
    };
    my $gcis_ref_existing = $gcis_handle->get($reference_data->{uri});
    if ($gcis_ref_existing) {
        check_existing_bib(
          gcis_handle    => $gcis_handle,
          errata         => $errata,
          endnote_record => $endnote_record,
          type           => $type,
          reference_data => $reference_data,
          existing       => $gcis_ref_existing,
        );
    } else {
        $REFS{$reference_data->{uri}}{'gcis_state'} = "created";
        add_item($gcis_handle, $reference_data);
    }

    return $reference_data;
}

# Utility Function to format the DIFF...

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

# Utility Function: When a URI has a difference to note, make sure
# it adds it in a unique way not relying on uri to be distinct
sub add_to_diff {
    my ($uri, $diff, $inc) = @_;

    my $cur_uri = $inc ? "$uri-$inc" : $uri;

    if ( exists $DIFF{$cur_uri} ) {
        say " WARN: existing URI diff for $cur_uri. Will increment to $cur_uri -N+1";
        $inc++;
        add_to_diff($uri, $diff, $inc);
    }
    else {
       $DIFF{$cur_uri} = $diff;
    }
    return 1;
}

# Utility Function Given a DIFF filename, dump the DIFF out to it

sub dump_diff { #used

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

sub dump_references {

    # TODO FIX
    my $n_refs = scalar keys %REFS;
    return 1 if $n_refs == 0  ||  !$references_file;
    open my $f, '>:encoding(UTF-8)', "$references_file" or die "can't open REF file";
    #print $f "$_\n" for ( @REFS );
    say $f Dump(\%REFS);
    close $f;

    return 1;

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
    say "   errata_file : $errata_file" if $errata_file;
    say "   diff_file : $diff_file" if $diff_file;
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
    my $gcis = $dry_run ? Gcis::Client->new(url => $url)
                        : Gcis::Client->connect(url => $url);
    my $errata = Errata->load($errata_file);

    my $en_ref_handler = Refs->new;
    $en_ref_handler->{n_max} = $max_references;
    $en_ref_handler->load($endnote_file);

    report_initial_state($en_ref_handler->type_counts);

    foreach my $endnote_record (@{ $en_ref_handler->{records} }) {
        my $type = $TYPE_MAP{$endnote_record->{reftype}[0]} or
            die " type not known : $endnote_record->{reftype}[0]";

        my $reference_data = create_bib_data(
          gcis_handle    => $gcis,
          errata         => $errata,
          endnote_record => $endnote_record,
          type           => $type,
        );

        import_reference(
          gcis_handle    => $gcis,
          errata         => $errata,
          endnote_record => $endnote_record,
          type           => $type,
          reference_data => $reference_data,
        );

        last if $max_updates > 0  &&  $N_UPDATES >= $max_updates;
    }

    dump_diff;
    dump_references;
    report_final_state;

    return;
}
