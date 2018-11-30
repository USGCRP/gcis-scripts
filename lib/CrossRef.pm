package CrossRef;

use Gcis::Client;
use Mojo::UserAgent;
use Data::Dumper;
use Clone::PP qw(clone);

use strict;
use v5.14;

sub new {
    my $class = shift;
    my $s;
    my $g = Mojo::UserAgent->new;
    $s->{crossref} = $g;
    bless $s, $class;
    return $s;
}

sub get {
    my ($s, $doi) = @_;

    my $d = $s->{crossref}->get("https://api.crossref.org/works/$doi") or do {
        say " no article for doi : $doi";
        return undef;
    };
    say "Response: " . Dumper $d->result->json;
    my $r = $d->result->json->{message} or do {
        say " no article content for doi : $doi";
        return undef;
    };

    # say " r :\n".Dumper($r);
    my $a;
    $a->{doi} = $doi;
    $a->{title} = join ': ', @{ $r->{title} };
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
        $a->{author} .= "; " if $a->{author};
        $a->{author} .= $name;
    }

    for (keys %{ $a }) {
        $a->{$_} =~ s/^\s+//;
        $a->{$_} =~ s/\s+$//;
    }

    return $a;
}

1;
