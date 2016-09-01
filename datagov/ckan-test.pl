#!/usr/bin/env perl

use v5.20.1;
use Mojo::UserAgent;
use Data::Dumper;

my $url = 'http://catalog.data.gov/api/3/action/';

my $ua = Mojo::UserAgent->new;
$ua->max_redirects(3);

my $p;
# $p = 'group_list';
# $p = 'group_show?id=climate5434';
# $p = 'group_show?id=Climate';
# $p = 'tag_show?id=climate';
# $p = 'tag_show?id=health';
$p = 'package_search?q=groups:climate5434';
# my $p1 = '&q=vocab_category_all:Human+Health';

my $t = $ua->get($url.$p)->res->json or die 'get failed';

say " t.help :\n".Dumper($t->{help});
# say " t.result :\n".Dumper($t->{result});

my $r = $t->{result};
my $s = (grep 'packages' eq $_, (keys %{ $r })) ? 'packages' : 'results';
say $s;
for (keys %{ $r }) {
    next if $_ eq $s;
    say " $_ : $r->{$_}";
}

say " results:";
say " count : ".(scalar @{ $r->{$s}});
for (@{ $r->{$s}}) {
    say "   $_->{id}";
}

