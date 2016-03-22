package PubMed;

use Gcis::Client;
use Data::Dumper;
use Clone::PP qw(clone);

use strict;
use v5.14;

sub new {
    my $class = shift;
    my $s;
    my $g = Gcis::Client->new->url("http://eutils.ncbi.nlm.nih.gov");
    $s->{gcis} = $g;
    bless $s, $class;
    return $s;
}

sub get {
    my ($s, $id) = @_;

    my $r1;
    my $id1;
    my $n;
    my $check_page;
    my %report = (
        ss => 'MMWR Surveill Summ',
        mm => 'MMWR Morb Mortal Wkly Rep', 
        su => 'MMWR Suppl', 
    );
    my $retmax = 50;
    for ($id) {
        $id1 = $_;
        $check_page = 0;
        if ($id1 =~ /PMID-.+\|.+\|.*\|.*$/) {
            $id1 =~ s/^PMID-//;
            my ($k, $v, $i);
            ($k, $v, $i, $check_page) = split /\|/,$id1;
            $report{$k} or next;
            $id1 = $report{$k}."[Journal]";
            $id1 .= " AND ".$v."[Volume]";
            $id1 .= " AND ".$i."[Issue]" if $i;
            $id1 =~ s/ /+/g;
            $id1 =~ s/\[/%5b/g;
            $id1 =~ s/]/%5d/g;
        } elsif ($id1 =~ /^PMC-\d+$/) {
            $id1 =~ s/-//;
        } elsif ($id1 =~ /^pmid-\d+$/) {
            $id1 =~ s/^pmid-//;
        }
        my $q1 = "/entrez/eutils/esearch.fcgi?db=pubmed&retmode=json".
                 "&retmax=$retmax&term=$id1";
        $r1 = $s->{gcis}->get($q1) or do {
            say " no pubmed return for id : $id1";
            return undef;
        };
        $n = $r1->{esearchresult}->{count};
        last if $n > 0 && $n <= $retmax;
    }

    if ($n < 1  ||  ($n > 1  &&  !$check_page)) {
        say " no pubmed article for id : $id";
        return undef;
    }

    for my $pid (@{ $r1->{esearchresult}->{idlist} }) {
        my $q2 = "/entrez/eutils/esummary.fcgi?db=pubmed&retmode=json".
             "&rettype=abstract&id=$pid";
        my $r2 = $s->{gcis}->get($q2) or do {
            say " no pubmed article for id : $id1";
            return undef;
        };
        $a = _parse($r2);
        return $a unless $check_page;
        my ($p1a) = split /-/, $a->{journal_pages};
        return $a if $check_page eq $p1a;
    }
    return undef;

}

sub alt_id {
    my ($url, $pg) = @_;

    my $id;
    my $t;
    for ($url) {
        $t = 'PMC';
        ($id) = ($_ =~ /^http.*\/PMC(\d+)\//);
        last if $id;
        $t = 'pmid';
        ($id) = ($_ =~ /^http.*\/pubmed\/(\d+)/);
        last if $id;
        $t = 'PMID';
        ($id) = ($_ =~ /^http:\/\/.*\.cdc\.gov\/.*\/(.*)\./);
        last if $id;
        return undef;
    }

    if ($t eq 'PMID') {
        return undef unless $pg;
        return undef unless $id =~ /^[ms][msu]\d{2}.{2}/;
        my ($j, $v, $i) = ($id =~ /^(.{2})(\d{2})(.{2})/);
        ($v, $i) = ("$v Spec No", '') if ($i eq 'SP');
        my ($p1, $p2) = split /-/, $pg;
        $v =~ s/^0+//;
        $i =~ s/^0+//;
        $id = "$j|$v|$i|$p1";
    }
    $id = "$t-$id" unless $t eq 'pmid';
    return $id;
}

sub _pages {
    my $v = shift;

    my @p = split /-/, $v;
    return $v unless scalar @p == 2;

    my ($n1, $n2) = @p;
    return $v if $n2 > $n1;

    my @a = split //, $n1;
    my @b = split //, $n2;
    my $n = 0;    
    for (@b) {
        $n--;
        @a[$n] = @b[$n];
    }
    $v = "$n1-".(join '', @a);
    return $v;
}

sub _authors {
    my $v = shift;
    my $as;
    my $n;
    for (@{ $v }) {
        $n++;
        my @n = split / /, $_->{name};
        my $init = pop @n;
        next if $init =~ /^\(.+\)$/;
        $init = (join '. ', (split //, $init)).'.';
        my $a1 = (join ' ', @n).', '.$init;
        $as .= '; ' if $as;
        $as .= $a1;
    }
    if (!$as  &&  $n > 0) {
        for (@{ $v }) {
            $as .= '; ' if $as;
            $as .= $_->{name};
        }
    }
    return $as;
}

sub _parse {
    my $r = shift;

    my $v = $r->{result};
    my $n = @{ $v->{uids} };
    if ($n != 1) {
        say " ".($n < 0 ? "no" : "too many ($n)").
            " ids from pubmed : $n"; 
        return undef;
    }
    my $id = $v->{uids}[0];
    $v = $v->{$id};

    my $a;
    my %m = (
       title => 'title', 
       fulljournalname => 'journal',
       volume => 'journal_vol',
       issue => 'issue',
    );
    for (keys %m) {
        next unless $v->{$_};
        $a->{$m{$_}} = $v->{$_};
    }

    $a->{journal_pages} = _pages($v->{pages});

    push @{ $a->{issn} }, $v->{issn} if $v->{issn};
    push @{ $a->{issn} }, $v->{essn} if $v->{essn};
    $a->{pmid} = $id;
    ($a->{year}) = ($v->{pubdate} =~ /^(\d{4})/);

    $a->{author} = _authors($v->{authors});
    
    for (keys %{ $a }) {
        next if ref $a->{$_} ne 'SCALAR';
        $a->{$_} =~ s/^\s+//;
        $a->{$_} =~ s/\s+$//;
    }
    for ($a->{title}) {
        s/^\[//;
        s/.$//;
        s/]$//;
    }

    return $a;
}

1;
