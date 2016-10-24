#!/usr/bin/env perl

=head1 NAME

[FILENAME] -- [ONE LINE DESCRIPTION]

=head1 DESCRIPTION

[FULL EXPLANATION OF THE SCRIPT. Remember to explain the
'Why' and 'How' as well as the 'What'. Make note of any
externalities, such as GCIS (very common), CrossRef.org,
IO files, etc ]


=head1 SYNOPSIS

[GENERIC SCRIPT RUN e.g.: "./FILENAME [OPTIONS] < FOO.TXT"]

=head1 OPTIONS

=over

=item <stdin>

[STDIN DESCRIPTION (if used)]

=item B<--[FOO]>

[FOO DESCRIPTION]

=item B<--BAR>

[BAR DESCRIPTION]

=item B<--verbose>

Verbose option [IF USED; HIGHLY ENCOURAGED]

=item B<--dry_run>

Dry run [IF USED; HIGHLY ENCOURAGED]

=back

=head1 EXAMPLES

[REALISTIC SCRIPT RUN e.g. `./FILENAME --foo --verbose <input.txt`]

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
