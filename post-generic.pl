#!/usr/bin/perl

=head1 NAME

./post-generic.pl - basic generic publication post test

=head1 DESCRIPTION

Posts a test Generic Publication to a locally running GCIS
instance

=head1 SYNOPSIS

./post-generic.pl 

=head1 OPTIONS

=over

=back

=head1 EXAMPLES

./post-generic.pl 

=cut

use Gcis::Client;

my $c = Gcis::Client->connect(url => 'http://localhost:3000');

$c->post('/generic', {
        identifier => 'test',
        attrs => {
            foo => 'bar',
            baz => 'bub'
        }
    }
);
