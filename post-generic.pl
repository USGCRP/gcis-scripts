#!/usr/bin/perl

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
