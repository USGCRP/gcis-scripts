#!/usr/bin/env perl

use v5.18.1;
use Data::Dumper;
use YAML::XS qw/Dump/;
use Ckan;

my $base_url = 'http://catalog.data.gov/';
my $ckan_url = $base_url.'api/3/action/';

my $c = Ckan->new($ckan_url);
# $c->{n_max} = 10;
my $g = 'climate5434';
my @d = $c->get_group($g);

say Dump(@d);

exit;
