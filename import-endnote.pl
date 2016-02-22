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

=item B<--errata_file>

Errata file (yaml) - contains aliases for entries that
already exists (see below for file example)

=item B<--diff_file>

Difference file (yaml) - contains differences between the new
entry and an existing GCIS entry

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

[Note, Reading errata for reference attributes is not implmented, 
yet!]

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
    'errata_file=s'         => \(my $errata_file),
    'diff_file=s'           => \(my $diff_file),
    'verbose'               => \(my $verbose),
    'dry_run|n'             => \(my $dry_run),
    'help|?'                => sub { pod2usage(verbose => 2) },
) or die pod2usage(verbose => 1);

pod2usage(msg => "missing url or endnote file", verbose => 1) unless ($url && $endnote_file);

my %diff;
my $n_updates = 0;
# my $test = '10.2105/AJPH.91.8.1194';

say " importing endnote references";
say "   url : $url";
say "   endnote_file : $endnote_file";
say "   max_updates : $max_updates";
say "   max_references : $max_references";
say "   do_not_add_journals" if $do_not_add_journals;
say "   do_not_add_articles" if $do_not_add_articles;
say "   do_not_add_referneces" if $do_not_add_references;
say "   errata_file : $errata_file";
say "   diff_file : $diff_file";
say "   verbose" if $verbose;
say "   dry_run" if $dry_run;
say '';

&main;

sub xml_unescape {
  my $str = shift;
  return undef unless defined($str);

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
    my @words = split /\s+/, $str;
    my $id = '';
    for (@words) {
        tr/A-Z/a-z/;
        tr/a-z0-9-//dc;
        next if /^(a|the|from|and|for|to|with|of|in)$/;
        next unless length;
        $id .= '-' if length($id);
        $id .= $_;
        last if length($id) > 30;
    }
    return $id;
}

sub compare_hash {
    my ($a, $b) = @_;

    my %c;
    for (keys %{ $a }) {
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
            my $c1 = compare_hash($a->{$_}, $b->{$_}) or next;
            $c{$_} = $c1;
            next;
        }
        next if $a->{$_} eq $b->{$_};
        my $a1 = lc xml_unescape($a->{$_});
        my $b1 = lc xml_unescape($b->{$_});
        next if $a1 eq $b1;
        if (lc $_ eq 'author') {
            $a1 =~ s/\r/; /g;
            $b1 =~ s/\r/; /g;
            next if $a1 eq $b1;
        }
        $c{$_} = {_A_ => $a->{$_}, _B_ => $b->{$_}};
    }
    return %c ? \%c : undef;
}

sub compare {
    my ($a, $b) = @_;

    my $c = compare_hash($a, $b);
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

sub add_item {
    my ($g, $j) = @_;

    my $u = $j->{uri};
    my ($t) = ($u =~ /^\/(.*?)\//);

    if ($dry_run) {
        say " would add $t : $u";
        $n_updates++;
        return 1;
    }

    say " adding $t : $u";
    my $n = clone($j);
    delete $n->{uri};
    remove_undefs($n);
    $n_updates++;
    $g->post("/$t", $n) or die " unable to add $t : $u";

    return 1;
}

sub add_child_pub {
    my ($g, $j) = @_;

    my $u = $j->{uri};

    if ($dry_run) {
        say " would add child pub : $u";
        $n_updates++;
        return 1;
    }

    say " adding child pub : $u";
    my $a = clone($j->{attrs});
    remove_undefs($a);
    $n_updates++;
    $g->post($u, {
        identifier => $j->{identifier},
        attrs => $a,
        child_publication_uri => $j->{child_publication_uri},
        }) or die " unable to add child pub : $u";

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

sub fix_issn {
    my ($a, $b) = @_;

    my @v = qw(print_issn online_issn);
    my %b1;
    my %a1;
    my $nb = 0;
    my $nc = 0;
    for (@v) {
        $a1{$_} = $a->{$_}; 
        $b->{$_} or next;
        $b1{$b->{$_}} = $_;
        $nb++;
    }
    return $nc if $nb == 0;

    for (@v) {
        $a1{$_} or next;
        my $i = $b1{$a1{$_}} or next;
        next if $i eq $_;
        $a->{$i} = $a1{$_};
        $a->{$_} = $a1{$i};
        $nc++;
    }

    if ($b->{online_issn}  &&  !$a->{online_issn}) {
        $a->{online_issn} = $b->{online_issn};
        $nc++;
    }

    return $nc;
}

sub fix_doi {
    my ($e, $d) = @_;

    my $a->{doi} = $d or return undef;
    $a->{uri} = "/article/$d";
    $e->fix_errata($a);
    return $a->{doi};
}

sub import_article {
    my ($g, $e, $cr, $r) = @_;

    my $a;
    # say " r :\n".Dumper($r);
    $a->{title} = xml_unescape($r->{title}[0]) or do {
        say " no title!";
        return 0;
    };
    $a->{doi} = $r->{doi}[0] or do {
        say " no doi : $a->{title}";
        # say " r :\n".Dumper($r);
        return 0;
    };
    $a->{doi} = fix_doi($e, $a->{doi});
    my $c = $cr->get($a->{doi}) or do {
        say " doi not in crossref : $a->{doi}";
        return 0;
    };
    # say " c :\n".Dumper($c);

    my $j;
    $j->{title} = xml_unescape($r->{secondary_title}[0]) or do {
        say " no journal title : $a->{title}";
        return 0;
    };
    $j->{identifier} = make_identifier($j->{title});
    $j->{uri} = '/journal/'.$j->{identifier};
    $j->{print_issn} = $c->{issn}[0];
    $j->{online_issn} = $c->{issn}[1];
    $j->{publisher} = $a->{publisher} ? $a->{publisher} : $c->{publisher};
    $e->fix_errata($j);

    say " jou :\n".Dumper($j) if $verbose;

    my $j1 = $g->get($j->{uri});
    if (!$j1) {
        if (!$j->{print_issn}  &&  !$j->{online_issn}) {
            say " no journal issn : $j->{uri}";
            return 0;
        }
        $j1 = get_journal($g, $c->{issn});
    }
    if ($j1) {
        fix_issn($j, $j1);
        my $d = compare($j, $j1);
        if ($d) {
            say " existing journal different : $j->{uri}";
            return 0;
        }
        say " existing journal same : $j->{uri}";
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
    $a->{journal_pages} =~ s/S//g if $a->{journal_pages};
    $a->{identifier} = $a->{doi};
    $a->{uri} = "/article/$a->{doi}";
    $a->{journal_identifier} = $j->{identifier};
    $e->fix_errata($a);

    say " art :\n".Dumper($a) if $verbose;

    my $a1 = $g->get($a->{uri});
    if ($a1) {
        my $d = compare($a, $a1);
        if ($d) {
            say " existing article different : $a->{uri}";
            return 0;
        }
        say " existing article same : $a->{uri}";
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
    for ($r->{author}, $c->{author}) {
        next unless $_;
        $ba->{Author} = join '; ', @{ $_ };
        last;
    }

    say " bib :\n".Dumper($b) if $verbose;

    my $b1 = $g->get($b->{uri});
    if ($b1) {
        my $d = compare($b, $b1);
        if ($d) {
            say " existing reference different : $b->{uri}";
            return 0;
        }
        say " existing reference same : $b->{uri}";
        return 1;
    } elsif (!$do_not_add_references) {
        add_item($g, $b) or return 0;
        $b->{child_publication_uri} = $a->{uri};
        add_child_pub($g, $b) or return 0;
    } else {
        return 0;
    }

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
    say '';
    say " n diff : $n_diff";
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

    open my $f, '>:encoding(UTF-8)', $diff_file or die "can't open diff file";;
    say $f Dump($y);

    return 1;
}

sub main {
    my $g = $dry_run ? Gcis::Client->new(url => $url)
                     : Gcis::Client->connect(url => $url);
    my $cr = CrossRef->new;
    my $e = Errata->load($errata_file);

    my $r = Refs->new;
    $r->{n_max} = $max_references;
    $r->load($endnote_file);
    my $n = $r->type_counts;
    say " endnote entries : ";
    for (keys %{ $n }) {
        say "   $_ : $n->{$_}";
    }

    for my $ref (@{ $r->{records} }) {
        next unless $ref->{reftype}[0] eq 'Journal Article';
        # if ($test) {
        #     next unless $ref->{doi}[0];
        #     next unless $ref->{doi}[0] eq $test;
        # }
        # say " ref :\n".Dumper($ref);
        say '';
        import_article($g, $e, $cr, $ref) or next;
        last if $max_updates > 0  &&  $n_updates >= $max_updates;
    }
    dump_diff;

    return;
}
