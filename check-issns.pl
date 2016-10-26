#!/usr/bin/env perl

=head1 NAME

check-issns.pl -- Check the Journal ISSN checksums

=head1 DESCRIPTION

Queries all the Journals from GCIS and checks any ISSN
(print and online) for validity.

Read-only script, prints a message on invalid ISSN.

=head1 SYNOPSIS

./check-issns.pl GCIS_URL

=head1 OPTIONS

=over

=item <GCIS_URL>

The host running our GCIS instance.

=back

=head1 EXAMPLES

./check-issns.pl "https://data-stage.globalchange.gov"

=cut

use v5.14;
use Gcis::Client;
use Business::ISSN qw/is_valid_checksum/;

my $url = shift or die "no url";
my $gcis = Gcis::Client->new(url => $url);
for my $journal ($gcis->get("/journal?all=1")) {
    unless ($journal->{print_issn} || $journal->{online_issn}) {
        say "No issn for $url";
        next;
    }
    if ($journal->{print_issn} && !is_valid_checksum($journal->{print_issn})) {
        say "Invalid print issn: $journal->{print_issn} for $journal->{uri}";
    }
    if ($journal->{online_issn} && !is_valid_checksum($journal->{online_issn})) {
        say "Invalid online issn: $journal->{online_issn} for $journal->{uri}";
    }
}
