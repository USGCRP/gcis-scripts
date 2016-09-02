#!/usr/bin/env perl

use v5.18.1;
use Data::Dumper;
use YAML::XS qw/Dump/;
use Ckan;

my $base_url = 'http://catalog.data.gov/';
my $ckan_url = $base_url.'api/3/action/';

my $c = Ckan->new($ckan_url);

my $ids = load_list();
my @d;
for (@$ids) {
    my $v = $c->get_id($_) or next;
    push @d, $v;
}

say Dump(\@d);

exit;

sub load_list {
    my @e;
    while (<>) {
       chomp;
       last if $_ eq '';
       push @e, $_;
    }

    return \@e;
}
