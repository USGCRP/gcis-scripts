#!/usr/bin/env perl

=head1 NAME

diff-to-tsv.pl -- Convert difference to a tsv file format

=head1 DESCRIPTION

diff-to-tsv.pl reads a difference file and outputs the difference in a tsv 
(tab separated value) format.  The differneces are in a yaml formated, e.g. 
the difference output from import-endnote.yaml.  The tsv file has three fields, 
the first containing the uri, the second containing the value and 
the third containing the conflicting value.  The difference are subsets 
based on the specific resource type and field (and optional subfield).

=head1 SYNOPSIS

./diff-to-tsv.pl [OPTIONS]

=head1 OPTIONS

=over

=item B<--diff_file>

Input difference file (yaml format)

=item B<stdout>

Differences in tsv format

=item B<--type>

GCIS resource type of difference to output (e.g. article)

=item B<--field>

Field to be output (e.g. title)

=item B<--subfield>

Second layer fields (optional, e.g. ISSN in the attrs field for 
reference type)

=back

=head1 EXAMPLES

# convert the differnece for the title field in the article resource

./diff-to-tsv.pl -d diff.yaml -t article -f title

=cut

use Data::Dumper;
use Errata;
use Getopt::Long;
use Pod::Usage;

use strict;
use v5.14;
use warnings;

binmode STDOUT, ':encoding(utf8)';

GetOptions(
    'diff_file=s' => \(my $diff_file),
    'type=s'      => \(my $type),
    'field=s'     => \(my $field),
    'subfield=s'  => \(my $subfield), 
    'help|?'      => sub { pod2usage(verbose => 2) },
) or die pod2usage(verbose => 1);

pod2usage(msg => "missing file, type and/or field", verbose => 1)
    unless ($diff_file && $type && $field);

&main;

sub main {
    my $e = Errata->load($diff_file);

    my $l = $field;
    $l .= " $subfield" if $subfield;
    say "uri $l\tvalue\tother";
    for (sort keys %{ $e->{e} }) {
        my $u = $_ or next;
        $u =~ /^\/$type/ or next;
        my $r = $e->{e}->{$u};
        my $i = $r->{$field} or next;
        if ($subfield) {
            next unless $r->{$field}->{$subfield};
            $i = $r->{$field}->{$subfield};
        }
        my $a = $i->{alias} ? $i->{alias} : 'undef';
        my $b = $i->{value} ? $i->{value} : 'undef';
        say "$u\t$a\t$b";
    }

    exit;
}
