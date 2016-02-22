package CrossRef;

use Gcis::Client;
use Data::Dumper;
use Clone::PP qw(clone);

use strict;
use v5.14;

sub new {
    my $class = shift;
    my $s;
    my $g = Gcis::Client->new->url("http://api.crossref.org");
    $s->{gcis} = $g;
    bless $s, $class;
    return $s;
}

sub get {
    my ($s, $doi) = @_;

    my $d = $s->{gcis}->get("/works/$doi") or do {
        say " no article for doi : $doi";
        return undef;
    };
    my $r = $d->{message} or do {
        say " no article content for doi : $doi";
        return undef;
    };

    # say " r :\n".Dumper($r);
    my $a;
    $a->{doi} = $doi;
    $a->{title} = clone($r->{title});
    $a->{year} = $r->{issued}{'date-parts'}[0][0];
    $a->{issn} = clone($r->{ISSN});
    $a->{journal} = clone($r->{'container-title'});
    $a->{journal_vol} = $r->{volume};
    $a->{journal_pages} = $r->{page};
    $a->{issue} = $r->{issue};
    $a->{publisher} = $r->{publisher};
    for (@{ $r->{author} }) {
        my $name = $_->{family};
        $name .= ", ".$_->{given} if $_->{given};
        push @{ $a->{author} }, $name;
    }

    return $a;
}

1;
