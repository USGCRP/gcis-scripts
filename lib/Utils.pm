package Utils;

use Gcis::Client;
use Data::Dumper;
use Clone::PP qw(clone);

use strict;
use v5.14;
use warnings;

my %list = (
    '<'  => '%3C',  '>'  => '%3E',
    '\[' => '%5B',  '\]' => '%5D',
    ' '  => '%20',  ':'  => '%3A',
    '&'  => '%26',  ','  => '%2C',
    '\+' => '%2B',
);

sub url_escape {
    my $u = shift;

    return undef unless $u;
    for (keys %list) {
        $u =~ s/$_/$list{$_}/g;
    }
    return $u;
}

sub url_unescape {
    my $u = shift;

    return undef unless $u;
    for (keys %list) {
        $u =~ s/$list{$_}/$_/g;
    }
    return $u;
}

sub strip_title {
    my $t = shift or return undef;

    my @words = split /\s+/, $t;
    my $s = '';
    for (@words) {
        tr/A-Z/a-z/;
        tr/a-z0-9 :&\-'\.,\/\()+\?"\[]$#\x{00E1}\x{00E9}\x{00F1}\x{02BC}\x{2010}\x{2013}\x{2014}\x{2018}\x{2019}\x{201C}\x{201D}//dc;
        next unless length;
        $s .= ' ' if length($s);
        $s .= $_;
    }
    $s =~ s/ +/ /g;

    return $s;
}

1;
