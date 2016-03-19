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

[Note: Only EndNote 'Journal Articles' are currently implemented.]

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

=item B<--do_not_add_articles>

Flag indicating articles are not to be added

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
    'do_not_add_articles'   => \(my $do_not_add_articles),
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
my %test;
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
say "   do_not_add_articles" if $do_not_add_articles;
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
        next if !$a->{$_}  &&  !$b->{$_};
        if (!$b->{$_}) {
           $c{$_} = {_A_ => $a->{$_}, _B_ => undef};
           next;
        }
        if (!$a->{$_}) {
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
            s/^\s+//; s/\s+$//; s/\.$//;
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
    $a =~ s/\r/; /g;
    $b =~ s/\r/; /g;
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

sub compare {
    my ($a, $b, $i) = @_;

    my $c = compare_hash($a, $b, $i);
    return $c unless $c;

    $diff{$a->{uri}} = $c;
    return $c;
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
    $g->post("/$t", $n) or die " unable to add $t : $u";
    sleep($wait) if $wait > 0;

    return 1;
}

sub add_child_pub {
    my ($g, $j) = @_;

    my $u = $j->{uri};

    if ($dry_run) {
        say " would add child pub : $u";
        $n_updates++;
        $stats{would_add_child_pub}++;
        return 1;
    }

    say " adding child pub : $u";
    $stats{added_child_pub}++;
    my $a = clone($j->{attrs});
    remove_undefs($a);
    $n_updates++;
    $g->post($u, {
        identifier => $j->{identifier},
        attrs => $a,
        child_publication_uri => $j->{child_publication_uri},
        }) or die " unable to add child pub : $u";
    sleep($wait) if $wait > 0;

    return 1;
}

sub get_journal {
    my ($g, $issn) = @_;
    my @a;
    for (@{ $issn }) {
        @a = $g->get("/autocomplete?type=journal&q=$_") or next;
        last;
    }
    @a or return undef;

    my $r;
    for (@a) {
        my ($id) = ($_ =~ /\{(.*?)\}/);
        my $uri = "/journal/$id";
        $r = $g->get($uri) or next;
        last;
    }
    return $r;
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
        next unless $_ eq $b1->{ISSN};
        $ba->{ISSN} = $b1->{ISSN};
        return 1;
    }
    return 0;
}

sub fix_doi {
    my ($e, $i) = @_;

    $i->{doi} or return 0;
    my $a->{doi} = $i->{doi};
    $a->{uri} = "/article/$->{doi}";
    $e->fix_errata($a);
    $i->{doi} = $a->{doi};
    return 1;
}

sub fix_alt_id {
     my ($ai, $id, $u) = @_;
     return 0 unless $u;
     return 1 unless $ai->{$u};
     my ($k, $i) = split '-', $ai->{$u};
     return 0 unless $k && $i;
     $id->{$k} = $i;
     return 1;
}

sub import_article {
    my ($g, $e, $ai, $r) = @_;

    my $a;
    # say " r :\n".Dumper($r);
    $a->{title} = xml_unescape(join ' ', @{ $r->{title} }) or do {
        say " no title!";
        $stats{no_title}++;
        return 0;
    };
    for ($a->{title}) {
        s/\(\s+/\(/g;  s/\s+\)/\)/g;
    }

    my $url = $r->{urls}[0];
    my $id;
    $id->{doi} = $r->{doi}[0] if $r->{doi}[0];
    fix_alt_id($ai, \%{ $id }, $url);
    if ($id->{doi}) {
        fix_doi($e, $id);
        $a->{doi} = $id->{doi};
    } elsif (!$id->{pmid}) {
        $id->{pmid} = PubMed::alt_id($url, $r->{pages}[0]) or do {
            say " no doi or alternate id : $a->{title}";
            $stats{no_doi_or_alternate_id}++;
            return 0;
        };
    }

    my $c;
    if ($id->{doi}) {
        return 0 if $skip_dois;
        my $cr = CrossRef->new;
        $c = $cr->get($a->{doi}) or do {
            say " doi not in crossref : $a->{doi}";
            $stats{doi_not_in_crossref}++;
            return 0;
       };
       $a->{identifier} = $a->{doi};
    } elsif ($id->{pmid}) {
       my $pm = PubMed->new;
       $c = $pm->get($id->{pmid}) or do {
            say " id not in pubmed : $id->{pmid}\n   for : $a->{title}";
            $stats{id_not_in_pubmed}++;
            return 0;
       };
       $a->{identifier} = 'pmid-'.$c->{pmid};
    }
    # say " c :\n".Dumper($c);

    my $j;
    $j->{title} = xml_unescape($r->{secondary_title}[0]) or do {
        say " no journal title : $a->{title}";
        $stats{no_journal_title}++;
        return 0;
    };

    my $jg;
    for my $max_char (-1, 40, 30) {
        $j->{identifier} = make_identifier($j->{title}, $max_char);
        $j->{uri} = '/journal/'.$j->{identifier};
        $jg = $g->get($j->{uri});
        last if $jg;
    }
    if (!$jg) {
        $j->{identifier} = make_identifier($j->{title}, 40);
        $j->{uri} = '/journal/'.$j->{identifier};
    }
    $j->{print_issn} = $c->{issn}[0];
    $j->{online_issn} = $c->{issn}[1];
    $j->{publisher} = $a->{publisher} ? $a->{publisher} : $c->{publisher};
    $e->fix_errata($j);

    if (%test_jou) {
        return 0 unless $test_jou{$j->{identifier}};
    }

    say " jou :\n".Dumper($j) if $verbose;

    if (!$jg) {
        $jg = $g->get($j->{uri});
        if (!$jg) {
            if (!$j->{print_issn}  &&  !$j->{online_issn}) {
                say " no journal issn : $j->{uri}";
                $stats{no_journal_issn}++;
                return 0;
            }
            $jg = get_journal($g, $c->{issn});
        }
    }
    if ($jg) {
        fix_jou_issn($j, $jg);
        my $d = compare($j, $jg, $e->diff_okay($j));
        if ($d) {
            say " existing journal different : $j->{uri}";
            $stats{existing_journal_different}++;
            return 0;
        }
        say " existing journal same : $j->{uri}";
        $stats{existing_journal_same}++;
    } elsif (!$do_not_add_journals) {
        add_item($g, $j) or return 0;
    } else {
        return 0;
    }

    my %a_map = (
       year          => 'year', 
       journal_vol   => 'volume',
       journal_pages => 'pages', 
       url           => 'urls', 
    );
    $a->{$_} = $r->{$a_map{$_}}[0] for keys %a_map;
    $a->{uri} = "/article/$a->{identifier}";
    $a->{journal_identifier} = $j->{identifier};
    $e->fix_errata($a);

    say " art :\n".Dumper($a) if $verbose;

    my $ac;
    $ac->{$_} = $a->{$_} for qw(uri doi title year journal_vol 
                                journal_pages author);
    $ac->{title} = xml_unescape($ac->{title});
    $ac->{author} = xml_unescape(join '; ', @{ $r->{author} });
    $e->fix_errata($ac);

    my $ig = $e->diff_okay($ac);
    push @{ $ig }, qw(uri);
    my $d = compare($ac, $c, $ig);
    if ($d) {
        say " external source article different : $a->{uri}";
        $stats{external_source_article_different}++;
        return 0;
    }

    my $ag = $g->get($a->{uri});
    if ($ag) {
        my $ig = $e->diff_okay($ac);
        push @{ $ig }, qw(uri);
        my $d = compare($a, $ag, $ig);
        if ($d) {
            say " existing article different : $a->{uri}";
            $stats{existing_article_different}++;
            return 0;
        }
        say " existing article same : $a->{uri}";
        $stats{existing_article_same}++;
    } elsif (!$do_not_add_articles) {
       add_item($g, $a) or return 0;
    } else {
       return 0;
    }

    my $b;
    $b->{identifier} = $r->{ref_key}[0];
    $b->{uri} = "/reference/$b->{identifier}";

    my %b_art = (
        DOI    => 'doi', 
        PMID   => 'pmid',
        Pages  => 'journal_pages', 
        Title  => 'title', 
        Volume => 'journal_vol', 
        Year   => 'year', 
    );
    my $ba = \%{ $b->{attrs} };
    $ba->{$_} = $a->{$b_art{$_}} for keys %b_art;

    my %b_ref = (
        _record_number => 'record_number',
        _uuid          => 'ref_key', 
        reftype        => 'reftype', 
    );
    $ba->{$_} = $r->{$b_ref{$_}}[0] for keys %b_ref;
    $ba->{'.reference_type'} = 0;
    for (@{ $r->{notes} }) {
       /^ *Ch\d+$/ or next;
       s/ //g;
       $ba->{_chapter} = $_;
    }

    $ba->{ISSN} = $j->{online_issn} ? $j->{online_issn} : $j->{print_issn};
    $ba->{Journal} = $j->{title};

    $ba->{Issue} = $c->{issue};
    $ba->{Author} = $ac->{author};
    $e->fix_errata($b);

    say " bib :\n".Dumper($b) if $verbose;

    my $b1 = $g->get($b->{uri});
    if ($b1) {
        fix_bib_issn($ba, $b1->{attrs}, $j);
        my $ig = $e->diff_okay($b);
        push @{ $ig }, qw(_record_number);
        my $d = compare($b, $b1, $ig);
        if ($d) {
            say " existing reference different : $b->{uri}";
            $stats{existing_reference_different}++;
            return 0;
        }
        say " existing reference same : $b->{uri}";
        $stats{existing_reference_same}++;
        return 0 if $do_not_add_references  ||  $b1->{child_publication};
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
    my $g = $dry_run ? Gcis::Client->new(url => $url)
                     : Gcis::Client->connect(url => $url);
    my $e = Errata->load($errata_file);

    my $r = Refs->new;
    $r->{n_max} = $max_references;
    $r->load($endnote_file);
    my $ai = load_alt_ids($alt_id_file);
    my $n = $r->type_counts;
    say " endnote entries : ";
    my $n_tot = 0;
    for (keys %{ $n }) {
        say "   $_ : $n->{$_}";
        $n_tot += $n->{$_};
    }
    say "   total : $n_tot";

    for my $ref (@{ $r->{records} }) {
        next unless $ref->{reftype}[0] eq 'Journal Article';
        # say " doi : $ref->{doi}[0]";
        my $do_it = 1;
        if (keys %test) {
            $do_it = 0;
            for (keys %test) {
                my $t = $test{$_};
                next unless $ref->{$t}[0];
                next unless $ref->{$t}[0] eq $_;
                $do_it = 1;
                last;
            }
        }
        next unless $do_it;
        # say " ref :\n".Dumper($ref);
        say '';
        import_article($g, $e, $ai, $ref) or next;
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
