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

Flag indicating items (articles, web pages, etc.) are not to be added

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

my %diff;
my $n_updates = 0;
my %stats;
my $skip_dois = 1;
my $do_fix_items = 1;
my %test;
#     '36921a15-271d-48d7-b648-a481bde24a94' => 'ref_key',
#     '87031b30-75fa-495d-8a99-0df6c5eb4ced' => 'ref_key', 
#     'http://www.ncbi.nlm.nih.gov/pmc/articles/PMC1497432/pdf/12432132.pdf' => 'urls',
#     'http://www.ncbi.nlm.nih.gov/pubmed/6475916' => 'urls', 
#     'http://www.cdc.gov/mmwr/preview/mmwrhtml/mm6331a1.htm' => 'urls', 
#     '10.1021/es900518z' => 'doi',
#     'http://www.ewra.net/wuj/pdf/WUJ_2014_08_07.pdf' => 'urls', 
#     '94694c3f-1703-4387-b6e7-114a8d04e3de' => 'ref_key',
#     '10.1021/es900518z' => 'doi',
#     'http://www.cdc.gov/pcd//issues/2008/jan/07_0135.htm' => 'urls', 
#     'http://www.cdc.gov/mmwr/preview/mmwrhtml/mm6331a1.htm' => 'urls',
#     'doi:10.1016/j.annemergmed.2006.12.004' => 'doi',
#     '10.1175/1520-0477(1997)078<1107:tchwhl>2.0.co;2' => 'doi', 
#     '10.3394/0380-1330(2007)33[566:dafoec]2.0.co;2' => 'doi', 
#     '10.3376/1081-1710(2007)32[22:CALCFP]2.0.CO;2' => 'doi', 
#     '10.3376/1081-1710(2008)33[89:iocvom]2.0.co;2' => 'doi', 
#     '10.1603/0022-2585(2005)042[0367:ahamdc]2.0.co;2' => 'doi', 
#     '10.1021/es900518z' => 'doi',
#     '10.3354/cr027177' => 'doi', 
#     '10.1001/jama.292.19.2372' => 'doi', 
#     '01c49cdf-06bb-41ef-95be-37a8553295b7' => 'ref_key',
#     '10.1002/etc.2046' => 'doi',
#     '10.1001/archinternmed.2011.683' => 'doi',
#     '197d65cd-c05e-4ddb-8a9d-5a9aed134974' => 'ref_key',
my %test_jou;
#     'international-journal-environmental-research--public-health' => 'journal',
#     'philosophical-transactions-royal-society-b-biological-sciences' => 'journal', 
#     'philosophical-transactions-royal-society-a-mathematical-physical-and-engineering-sciences' => 'journal', 
#     'atmospheric-chemistry-physics' => 'journal', 

say " importing endnote references";
say "   url : $url";
say "   endnote_file : $endnote_file";
say "   max_updates : $max_updates";
say "   max_references : $max_references";
say "   do_not_add_journals" if $do_not_add_journals;
say "   do_not_add_items" if $do_not_add_items;
say "   do_not_add_referneces" if $do_not_add_references;
say "   errata_file : $errata_file" if $errata_file;
say "   diff_file : $diff_file";
say "   alt_id_file : $alt_id_file" if $alt_id_file;
say "   verbose" if $verbose;
say "   dry_run" if $dry_run;
say '';

&main;

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

sub compare_hash {
    my ($a, $b, $i) = @_;

    my %i1 = map { $_ => 1 } @{ $i };
    my %c;
    for (keys %{ $a }) {
        next if $i1{$_};
        next if !defined $a->{$_}  &&  !defined $b->{$_};
        if (!defined $b->{$_}) {
           $c{$_} = {_A_ => $a->{$_}, _B_ => undef};
           next;
        }
        if (!defined $a->{$_}) {
           $c{$_} = {_A_ => undef, _B_ => $b->{$_}};
           next;
        }
        if (ref $a->{$_} eq 'HASH') {
            my $c1 = compare_hash($a->{$_}, $b->{$_}, $i) or next;
            $c{$_} = $c1;
            next;
        }
        next if $a->{$_} eq $b->{$_};
        my $a1 = lc xml_unescape($a->{$_});
        my $b1 = lc xml_unescape($b->{$_});
        for ($a1, $b1) {
            s/^\s+//; s/\s+$//; s/\.$//; s/\r/; /g;
        }
        next if $a1 eq $b1;
        if (lc $_ eq 'author') {
            next if compare_author($a1, $b1);
        }
        $c{$_} = {_A_ => $a->{$_}, _B_ => $b->{$_}};
    }
    return %c ? \%c : undef;
}

sub compare_author {
    my ($a, $b) = @_;
    my @a1 = split '; ', $a;
    my @b1 = split '; ', $b;
    for my $a2 (@a1) {
        my $b2 = shift @b1;
        return 0 unless $b2;
        my ($al, $af) = split ', ', $a2;
        my ($bl, $bf) = split ', ', $b2;
        return 0 if $al ne $bl;
        next if !$af && !$bf;
        return 0 if $af && !$bf;
        return 0 if $bf && !$af;
        return 0 if substr($af, 0, 1) ne substr($bf, 0, 1);
    }
    return 1;
}

sub remove_undefs {
    my $v = shift;
    ref $v eq 'HASH' or return 0;
    for (keys %{ $v }) {
        if (ref $v->{$_} eq 'HASH') {
            remove_undefs($v->{$_});
            undef $v->{$_} unless keys %{ $v->{$_} } > 0;
        }
        delete $v->{$_} unless defined $v->{$_};
    }
    return 1;
}

sub fix_identifier {
    my $r = shift;

    return 1 unless $r->{identifier};
    my %list = (
        '<' => '%3C', '>' => '%3E', 
        '\[' => '%5B', '\]' => '%5D', 
        );
    for (keys %list) {
        $r->{identifier} =~ s/$_/$list{$_}/g;
    }

    return 1;
}

sub update_item {
    my ($g, $j) = @_;

    my $u = $j->{uri};
    my ($t) = ($u =~ /^\/(.*?)\//);

    if ($dry_run) {
        say " would update $t : $u";
        $n_updates++;
        $stats{"would_update_$t"}++;
        return 1;
    }

    say " updating $t : $u";
    $stats{"updated_$t"}++;
    my $n = clone($j);
    delete $n->{uri};
    remove_undefs($n);
    my @extra = qw(articles chapters child_publication
                   cited_by contributors files 
                   href parents publications 
                   references report_figures report_findings
                   report_tables);
    for (@extra) {
        delete $n->{$_} if $n->{$_};
    }
    $n_updates++;
    my $i = $g->post($u, $n) or die " unable to update $t : $u";
    sleep($wait) if $wait > 0;

    return $i->{uri};
}

sub add_item {
    my ($g, $j) = @_;

    my $u = $j->{uri};
    my ($t) = ($u =~ /^\/(.*?)\//);

    if ($dry_run) {
        say " would add $t : $u";
        $n_updates++;
        $stats{"would_add_$t"}++;
        return 1;
    }

    say " adding $t : $u";
    $stats{"added_$t"}++;
    my $n = clone($j);
    delete $n->{uri};
    remove_undefs($n);
    $n_updates++;
    my $i = $g->post("/$t", $n) or die " unable to add $t : $u";
    sleep($wait) if $wait > 0;

    return $i->{uri};
}

sub can_fix_item {
    my $d = shift;
    return 0 unless $d;
    for (keys %{ $d }) {
        my $v = $d->{$_};
        if (!grep "_A_" eq $_, keys %{ $v }) {
            return 0 unless can_fix_item($v);
            next;
        }
        return 0 unless defined $v->{_A_};
        return 0 if defined $v->{_B_};
    }
    return 1;
}

sub fix_item {
    my ($a, $b, $i) = @_;
    my %i1 = map { $_ => 1 } @{ $i };
    for (keys %{ $a }) {
        next if $i1{$_};
        if (ref $a->{$_} eq 'HASH') {
            fix_item($a->{$_}, $b->{$_}, $i);
            next;
        }
        next unless defined $a->{$_};
        next if defined $b->{$_};
        $b->{$_} = $a->{$_};
    }
    return 1;
}

sub add_child_pub {
    my ($g, $b) = @_;

    my $u = $b->{uri};

    if ($dry_run) {
        say " would add child pub : $u";
        $n_updates++;
        $stats{would_add_child_pub}++;
        return 1;
    }

    say " adding child pub : $u";
    $stats{added_child_pub}++;
    my $a = clone($b->{attrs});
    remove_undefs($a);
    $n_updates++;
    $g->post($u, {
        identifier => $b->{identifier},
        attrs => $a,
        child_publication_uri => $b->{child_publication_uri},
        }) or die " unable to add child pub : $u";
    sleep($wait) if $wait > 0;

    return 1;
}

sub find_item {
    my ($g, $type, $k, $q) = @_;

    $q =~ s/ +/+/g;
    my @a = $g->get("/search?&q=$q&type=$type") or return undef;

    for my $e (@a) {
        if ($e->{$k}) {       
            return $e if $e->{$k} eq $q;
        }
        if ($k eq 'print_issn') {
            next unless $e->{online_issn};
            return $e if $e->{online_issn} eq $q;
        } elsif ($k eq 'online_issn') {
            next unless $e->{print_issn};
            return $e if $e->{print_issn} eq $q;
        } elsif ($k eq 'title') {
            my $ai = make_identifier($e->{$k}) or next;
            my $bi = make_identifier($q) or next;
            return $e if $ai eq $bi;
        }
    }
    return undef;
}

sub get_item {
    my ($g, $type, $a ) = @_;

    my $ag;
    for (qw(doi print_issn online_issn url title other)) {
        if ($_ ne 'other') {
           next unless $a->{$_};
           $ag = find_item($g, $type, $_, $a->{$_});
           last if $ag;
        }
        for my $max_char (-1, 60, 40, 30) {
            my $id = make_identifier($a->{title}, $max_char);
            $ag = $g->get("/$type/$id");
            last if $ag;
        }
    }
    if (grep $type eq $_, qw(report journal article)) {
        my $id = $ag ? $ag->{identifier} :
                       make_identifier($a->{title}, 60);
        $a->{identifier} = $id;
        $a->{uri} = "/$type/$id";
    }
    return $ag ? $ag : undef;
}

sub fix_jou_issn {
    my ($a, $b) = @_;

    my @v = qw(print_issn online_issn);

    my $nm = 0;
    my $na = 0;
    my $ka;
    my $kb;
    for my $k (@v) {
        next unless $a->{$k};
        $na++;
        for (@v) {
            next unless $b->{$_};
            next unless $a->{$k} eq $b->{$_};
            $ka = $k;
            $kb = $_;
            $nm++;
        }
    }
    return 0 if $nm < 1  ||  $nm > 2;
    if ($na < 2) {
        $a->{$_} = $b->{$_} for @v;
        return 1;
    }
    if ($nm > 1) {
        return 0 if $a->{print_issn} eq $a->{online_issn};
        return 0 if $b->{print_issn} eq $b->{online_issn};
        $a->{$_} = $b->{$_} for @v;
        return 1;
    }
    return 0 if $ka eq $kb;

    my $s = $a->{$ka};
    $a->{$ka} = $a->{$kb};
    $a->{$kb} = $s;
    return 1;
}

sub fix_bib_issn {
    my ($ba, $b1, $j) = @_; 

    return 0 unless $ba->{ISSN};
    return 0 unless $b1->{ISSN};
    return 0 if $ba->{ISSN} eq $b1->{ISSN};

    my @i = ($j->{online_issn}, $j->{print_issn});
    return 0 unless @i > 1;
    for (@i) {
        next unless $b1->{ISSN};
        next unless $_ eq $b1->{ISSN};
        $ba->{ISSN} = $b1->{ISSN};
        return 1;
    }
    return 0;
}

sub fix_doi {
    my ($e, $a) = @_;

    $a->{doi} or return 0;
    my $b->{doi} = $a->{doi};
    $b->{uri} = "/article/$a->{doi}";
    $e->fix_errata($b);
    $a->{doi} = $b->{doi};
    return 1;
}

sub fix_alt_id {
     my ($ai, $a) = @_;
     return 0 unless $a->{url};
     my $u = $a->{url};
     return 1 unless $ai->{$u};
     my ($k, $i) = split '-', $ai->{$u};
     return 0 unless $k && $i;
     $a->{$k} = $i;
     return 1;
}

sub map_attrs {
    my ($r, $ba) = @_;

    my %bib_multi = (
        author => 'Author',
        keywords => 'Keywords',
        secondary_author => 'Secondary Author',
        secondary_title => 'Secondary Title',
        pub_title => 'Publication Title', 
    );
    for my $k (keys %bib_multi) {
        next unless $r->{$k};
        if ($k =~ /author/) {
           ($_ =~ s/,$//) for @{ $r->{$k} };
        }
        $ba->{$bib_multi{$k}} = xml_unescape(join '; ', @{ $r->{$k} });
    }

    my %bib_map = (
        abstract      => 'Abstract',
        doi           => 'DOI',
        isbn          => 'ISBN',
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
        next unless $r->{$_};
        $ba->{$bib_map{$_}} = $r->{$_}[0];
    }

    for ($ba->{Notes}) {
       $_ or next;
       /^ *Ch\d+/ or next;
       s/^ *//;
       s/ *$//;
       $ba->{_chapter} = $_;
       delete $ba->{Notes} if $_ =~ /^ *Ch\d+ *$/;
    }

    return 1;
}

sub import_article {
    my $p = shift;

    my $g = $p->{gcis};
    my $e = $p->{errata};
    my $r = $p->{ref};
    my $a;

    say " ---";
    $a->{title} = xml_unescape(join ' ', @{ $r->{title} }) or do {
        say " no title!";
        $stats{no_title}++;
        return 0;
    };
    for ($a->{title}) {
        s/\(\s+/\(/g;  s/\s+\)/\)/g;
    }

    my $a_map = {
        urls   => 'url',
        doi    => 'doi', 
        year   => 'year',
        volume => 'journal_vol',
        pages  => 'journal_pages',
    };
    for (keys %{ $a_map }) {
        next unless $r->{$_};
        $a->{$a_map->{$_}} = $r->{$_}[0];
    }

    fix_alt_id($p->{alt_ids}, \%{ $a });
    if ($a->{doi}) {
        fix_doi($e, $a);
    } elsif (!$a->{pmid}) {
        $a->{pmid} = PubMed::alt_id($a->{url}, $r->{pages}[0]) or do {
            say " no doi or alternate id : $a->{title}";
            $stats{no_doi_or_alternate_id}++;
        };
    }

    my $c;
    if ($a->{doi}) {
        my $cr = CrossRef->new;
        $c = $cr->get($a->{doi}) or do {
            say " doi not in crossref : $a->{doi}";
            $stats{doi_not_in_crossref}++;
            return 0;
       };
       $a->{identifier} = $a->{doi};
    } elsif ($a->{pmid}) {
       my $pm = PubMed->new;
       $c = $pm->get($a->{pmid}) or do {
            say " id not in pubmed : $a->{pmid}\n   for : $a->{title}";
            $stats{id_not_in_pubmed}++;
            return 0;
       };
       $a->{identifier} = 'pmid-'.$c->{pmid};
    } else {
       $c = get_item($g, 'article', $a);
    }
    $a->{uri} = "/article/$a->{identifier}";

    my $j;
    $j->{title} = xml_unescape($r->{secondary_title}[0]) or do {
        say " no journal title : $a->{identifier}";
        $stats{no_journal_title}++;
        return 0;
    };

    $j->{print_issn} = $c->{issn}[0];
    $j->{online_issn} = $c->{issn}[1];
    $j->{publisher} = $c->{publisher};

    if (%test_jou) {
        return 0 unless $test_jou{$j->{identifier}};
    }

    say " jou :\n".Dumper($j) if $verbose;

    my $jg = get_item($g, 'journal', $j);
    $e->fix_errata($j);

    if (!$jg) {
        if (!$j->{print_issn}  &&  !$j->{online_issn}) {
            say " no journal issn : $j->{uri}";
            $stats{no_journal_issn}++;
            return 0;
        }
    }

    if (%test_jou) {
        return 0 unless $test_jou{$j->{identifier}};
    }

    if ($jg) {
        fix_jou_issn($j, $jg);
        my $ig = $e->diff_okay($j);
        my $d = compare_hash($j, $jg, $ig);
        if ($d) {
            say " existing journal different : $j->{uri}";
            $stats{existing_journal_different}++;
            if (can_fix_item($d)  &&  $do_fix_items) {
                say " can fix journal : $jg->{uri}";
                $stats{"can_fix_journal"}++;
                fix_item($j, $jg, $ig);
                my $d1 = compare_hash($j, $jg, $ig);
                !$d1 or die "didn't fix journal!";
                update_item($j, $jg);
                $j->{uri} = $jg->{uri};
            } else {
                $diff{$j->{uri}} = $d;
                return 0;
            }
        } else {
            say " existing journal same : $j->{uri}";
            $stats{existing_journal_same}++;
        }
    } elsif (!$do_not_add_journals) {
        add_item($g, $j) or return 0;
    } else {
        return 0;
    }

    $a->{journal_identifier} = $j->{identifier};
    delete $a->{pmid} if $a->{pmid};
    $e->fix_errata($a);

    say " art :\n".Dumper($a) if $verbose;

    my $ac;
    for (qw(uri doi title year journal_vol journal_pages)) {
         next unless $a->{$_};
         $ac->{$_} = $a->{$_};
    }
    $ac->{author} = xml_unescape(join '; ', @{ $r->{author} });
    $e->fix_errata($ac);

    my $ig = $e->diff_okay($ac);
    push @{ $ig }, qw(uri);
    my $d = compare_hash($ac, $c, $ig);
    if ($d) {
        $diff{$a->{uri}} = $d;
        say " external source article different : $a->{uri}";
        $stats{external_source_article_different}++;
        return 0;
    }

    my $ag = $g->get($a->{uri});
    if ($ag) {
        my $ig = $e->diff_okay($ac);
        push @{ $ig }, qw(uri);
        my $d = compare_hash($a, $ag, $ig);
        if ($d) {
            say " existing article different : $a->{uri}";
            $stats{existing_article_different}++;
            return 0;
            if (can_fix_item($d)  &&  $do_fix_items) {
                say " can fix article : $ag->{uri}";
                $stats{"can_fix_article"}++;
                fix_item($a, $ag, $ig);
                my $d1 = compare_hash($a, $ag, $ig);
                !$d1 or die "didn't fix article!";
                update_item($g, $ag);
                $a->{uri} = $ag->{uri};
            } else {
                $diff{$ag->{uri}} = $d;
                return 0;
            }
        } else {
            say " existing article same : $a->{uri}";
            $stats{existing_article_same}++;
        }
    } elsif (!$do_not_add_items) {
       add_item($g, $a) or return 0;
    } else {
       return 0;
    }

    my $b;
    $b->{identifier} = $r->{ref_key}[0];
    $b->{uri} = "/reference/$b->{identifier}";
    my $ba = \%{ $b->{attrs} };

    map_attrs($r, $ba);
    for ('Publication Title', 'Secondary Title', 'ISBN') {
        next unless $ba->{$_};
        delete $ba->{$_};
    }
    my $extra_map = {
        'Date Published' => 'Date',
        'Publisher' => '.publisher',
    };
    for (keys %{ $extra_map }) {
        next unless $ba->{$_};
        $ba->{$extra_map->{$_}} = $ba->{$_};
        delete $ba->{$_};
    }

    $ba->{Title} = $a->{title};

    my $ba_map = {
        url           => 'URL',
        doi           => 'DOI',
        journal_pages => 'Pages', 
        journal_vol   => 'Volume',
        year          => 'Year', 
    };
    for (keys %{ $ba_map }) {
        my $bk = $ba_map->{$_};
        if (!$a->{$_}) {
            next unless $ba->{$bk};
            delete $ba->{$bk};
            next;
        }
        $ba->{$bk} = $a->{$_};
    }
    $ba->{PMID} = $c->{pmid} if $c->{pmid};

    $ba->{'.reference_type'} = 0;

    $ba->{ISSN} = $j->{online_issn} ? $j->{online_issn} : $j->{print_issn};
    $ba->{Journal} = $j->{title};
    $ba->{Author} = $ac->{author};

    $e->fix_errata($b);

    say " bib :\n".Dumper($b) if $verbose;

    my $b1 = $g->get($b->{uri});
    if ($b1) {
        fix_bib_issn($ba, $b1->{attrs}, $j);
        $ig = $e->diff_okay($b);
        push @{ $ig }, qw(_record_number);
        my $d = compare_hash($b, $b1, $ig);
        if ($d) {
            say " existing reference different : $b->{uri}";
            $stats{existing_reference_different}++;
            if (can_fix_item($d)  &&  $do_fix_items) {
                say " can fix reference: $b->{uri}";
                $stats{"can_fix_reference"}++;
                fix_item($b, $b1, $ig);
                my $d1 = compare_hash($b, $b1, $ig);
                !$d1 or die "didn't fix reference!";
                update_item($g, $b1);
                return 0 if $do_not_add_references  ||
                            $b1->{child_publication};
            } else {
                $diff{$b->{uri}} = $d;
                return 0;
            }
        } else {
            say " existing reference same : $b->{uri}";
            $stats{existing_reference_same}++;
            return 0 if $do_not_add_references  ||  
                        $b1->{child_publication};
        }
    } elsif (!$do_not_add_references) {
        add_item($g, $b) or return 0;
    } else {
        return 0;
    }

    $b->{child_publication_uri} = $a->{uri};
    add_child_pub($g, $b) or return 0;

    return 1;
}

sub import_other {
    my $p = shift;

    my $g = $p->{gcis};
    my $e = $p->{errata};
    my $r = $p->{ref};
    my $type = $p->{type};

    say " ---";

    my $a;
    $a->{title} = xml_unescape(join ' ', @{ $r->{title} }) or do {
        say " no title!";
        $stats{no_title}++;
        return 0;
    };

    my $a_map = {
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

    my $at_map = $a_map->{$type} or 
        die "unknown type : $type";
    for (keys %{ $at_map }) {
        next unless $r->{$_};
        $a->{$at_map->{$_}} = $r->{$_}[0];
    }

    if ($type eq 'webpage'  &&  $a->{access_date}) {
       delete $a->{access_date} if $a->{access_date} eq 'Undated';
       $a->{access_date} .= "-01-01T00:00:00" if $a->{access_date};
    }
    if ($type eq 'report'  &&  $a->{publication_year}) {
       delete $a->{publication_year} if $a->{publication_year} eq 'n.d.';
    }

    $a->{uri} = "/$type/".make_identifier($a->{title});
    $e->fix_errata($a);

    my $ag = get_item($g, $type, $a);
    $e->fix_errata($a);

    say " item :\n".Dumper($a) if $verbose;

    if ($ag) {
        my $ig = $e->diff_okay($a);
        push @{ $ig }, qw(uri);
        my $d = compare_hash($a, $ag, $ig);
        if ($d) {
            say " existing $type different : $ag->{uri}";
            $stats{"existing_".$type."_different"}++;
            if (can_fix_item($d)  &&  $do_fix_items) {
                say " can fix $type : $ag->{uri}";
                $stats{"can_fix_".$type}++;
                fix_item($a, $ag, $ig);
                my $d1 = compare_hash($a, $ag, $ig);
                !$d1 or die "didn't fix $type!"; 
                update_item($g, $ag);
                $a->{uri} = $ag->{uri};
            } else {
                $diff{$ag->{uri}} = $d;
                return 0;
            }
        } else {
            say " existing $type same : $ag->{uri}";
            $stats{"existing_".$type."_same"}++;
            $a->{uri} = $ag->{uri};
        }
    } elsif (!$do_not_add_items) {
        $a->{uri} = add_item($g, $a) or return 0;
    } else {
       return 0;
    }

    my $b;
    $b->{identifier} = $r->{ref_key}[0];
    $b->{uri} = "/reference/$b->{identifier}";
    my $ba = \%{ $b->{attrs} };

    map_attrs($r, $ba);

    $ba->{Title} = $a->{title};

    my $ba_map = {
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

    my $bat_map = $ba_map->{$type};
    for (keys %{ $bat_map }) {
        my $bk = $bat_map->{$_};
        if (!$a->{$_}) {
            next unless $ba->{$bk};
            delete $ba->{$bk};
            next;
        }
        $ba->{$bk} = $a->{$_};
    }

    if ($type eq 'webpage'  &&  $ba->{Year}) {
        $ba->{Year} =~ s/^(\d{4}).*/$1/;
    }

    my %r_type = (
       webpage => 16,
       report => 10, 
    );
    $ba->{'.reference_type'} = $r_type{$type};

    $e->fix_errata($b);

    say " bib :\n".Dumper($b) if $verbose;

    my $b1 = $g->get($b->{uri});
    if ($b1) {
        my $ig = $e->diff_okay($b);
        push @{ $ig }, qw(_record_number);
        my $d = compare_hash($b, $b1, $ig);
        if ($d) {
            say " existing reference different : $b->{uri}";
            $stats{existing_reference_different}++;
            if (can_fix_item($d)  &&  $do_fix_items) {
                say " can fix reference: $b->{uri}";
                $stats{"can_fix_reference"}++;
                fix_item($b, $b1, $ig);
                my $d1 = compare_hash($b, $b1, $ig);
                !$d1 or die "didn't fix reference!";
                update_item($g, $b1);
                return 0 if $do_not_add_references  ||  
                            $b1->{child_publication};
            } else {
                $diff{$b->{uri}} = $d;
                return 0;
            }
        } else {
            say " existing reference same : $b->{uri}";
            $stats{existing_reference_same}++;
            return 0 if $do_not_add_references  ||  
                        $b1->{child_publication};
        }
    } elsif (!$do_not_add_references) {
        add_item($g, $b) or return 0;
    } else {
        return 0;
    }

    $b->{child_publication_uri} = $a->{uri};
    add_child_pub($g, $b) or return 0;

    return 1;
}

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

sub dump_diff {

    my $n_diff = keys %diff;
    return 1 if $n_diff == 0  ||  !$diff_file;

    my $y;
    for my $k (sort keys %diff) {
        my $v;
        $v->{uri} = $k;
        for (sort keys %{ $diff{$k} }) {
            my $d = $diff{$k}->{$_};
            push @{ $v->{errata} }, format_diff($_, $d);
        }
        push @{ $y }, $v;
    }

    open my $f, '>:encoding(UTF-8)', $diff_file or die "can't open diff file";
    say $f Dump($y);
    close $f;

    return 1;
}

sub load_alt_ids {
    return undef unless $alt_id_file;
    open my $f, '<:encoding(UTF-8)', $alt_id_file or 
       die "can't open alternate id file";
    my $yml = do { local $/; <$f> };
    close $f;

    my $y = Load($yml);
    my $a;
    for (@{ $y }) {
       my $k = $_->{url} or next;
       $a->{$k} = $_->{id} or next;
    }
    return $a ? $a : undef;
}

sub main {
    my %p;
    $p{gcis} = $dry_run ? Gcis::Client->new(url => $url)
                        : Gcis::Client->connect(url => $url);
    $p{errata} = Errata->load($errata_file);

    my $r = Refs->new;
    $r->{n_max} = $max_references;
    $r->load($endnote_file);
    $p{alt_ids} = load_alt_ids($alt_id_file);
    my $n = $r->type_counts;
    say " endnote entries : ";
    my $n_tot = 0;
    for (keys %{ $n }) {
        say "   $_ : $n->{$_}";
        $n_tot += $n->{$_};
    }
    say "   total : $n_tot";
    say "";

    my @ready = ('Journal Article', 'Web Page', 'Report');
    my %map = (
       'Book' => 'book',
       'Book Section' => 'book<section>', 
       'Conference Paper' => 'generic', 
       'Online Multimedia' => 'generic',
       'Journal Article' => 'article',
       'Legal Rule or Regulation' => 'generic', 
       'Press Release' => 'generic', 
       'Report' => 'report',
       'Web Page' => 'webpage',
    );
    my @which = qw(article);
    for (@{ $r->{records} }) {
        $p{ref} = $_;
        $p{type} = $map{$_->{reftype}[0]} or 
            die " type not known : $_->{reftype}[0]";
        next unless grep $p{type} eq $_, @which;

        my $do_it = 1;
        if (keys %test) {
            $do_it = 0;
            for (keys %test) {
                my $t = $test{$_};
                next unless $p{ref}->{$t}[0];
                next unless $p{ref}->{$t}[0] eq $_;
                $do_it = 1;
                last;
            }
        }
        next unless $do_it;

        if ($p{type} eq 'article') {
            import_article(\%p);
        } elsif (grep $p{type} eq $_, qw(webpage report)) {
            import_other(\%p);
        }
        last if $max_updates > 0  &&  $n_updates >= $max_updates;
    }
    dump_diff;

    my $n_diff = keys %diff;
    say '';
    say " n diff : $n_diff";

    my $n_stat = 0;
    for (sort keys %stats) {
        say "   $_ : $stats{$_}";
        $n_stat += $stats{$_};
    }
    say " n stat : $n_stat";

    return;
}
