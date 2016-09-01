package Org;

use Mojo::Util qw/url_escape/;
use Gcis::Client;
use Data::Dumper;

use strict;
use v5.14;

sub new {
    my $class = shift;
    my $g = shift;
    my $s;
    my $s->{g} = $g;
    bless $s, $class;
    return $s;
}

sub uri {
    my ($s, $n) = @_;

    return undef unless $n;

    my $g = $s->{g};

    $n = _special($n);
    my $e = url_escape($n);

    for ('datagov/Organization',
         'omb/agency:bureau',
         'govman/Agency',
         'govman/agencyName') {
        my $o = $g->get("/lexicon/$_/$e") or next;
        return $o->{uri};
    }

    my $e = $s->strip($n);
    my $o = $g->get("/organization/$e") or return undef;
    return $o->{uri};
}

sub strip {
    my ($s, $o) = @_;

    return undef unless $o;

    chomp $o;
    $o = _special($o);
    $o =~ s/\([A-Z-]{2,6}\)/ /g;
    $o = lc $o;
    $o =~ s/ +/ /g;
    $o =~ s/[,'] */|/g;
    $o =~ s/ *[\/:>]+ */|/g;
    $o =~ s/ - /|/g;
    $o =~ s/ *& */ /g;
    $o =~ s/u\. *s\. /us /g;
    $o =~ s/united states /us /g;
    $o =~ s/dept\. /department /g;
    $o =~ s/department /us department /g;
    $o =~ s/us us /us /g;
    $o =~ s/u\. /university /g;
    $o =~ s/[\(\)]/|/g;
    $o =~ s/ *\|+ */\|/g;
    $o =~ s/^ *\|+//;
    $o =~ s/\|+ *$//;
    $o =~ s/ (the|and|of|for) / /g;
    $o =~ s/^the //g;
    $o =~ s/^ +//;
    $o =~ s/ +$//;
    $o =~ s/ /-/g;

    return $o;
}

sub bureau {
    my ($s, $u) = @_;

    my $g = $s->{g};

    my $v = $g->get($u) or do {
        say " warning - uri not found : $u";
        return undef;
    };
    $a = $v->{aliases} or return undef;
    my $b;
    for (@{ $a }) {
        next unless $_->{lexicon} eq "omb";
        next unless $_->{context} eq "agency:bureau";
        $b = $_->{term};
        last;
    }

    return $b;
}

sub _special {
    my $o = shift;

    $o =~ s/Montioring/Monitoring/g;
    $o =~ s/Gelogical/Geological/g;
    $o =~ s/Adimnistration/Administration/g;

    return $o;
}

1;
