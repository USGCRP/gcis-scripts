#!/usr/bin/env perl

=head1 NAME

diff-to-tsv-all.pl -- Convert difference to a tsv file format

=head1 DESCRIPTION

diff-to-tsv-all.pl reads a difference file and outputs the difference in a tsv 
(tab separated value) format.  The differneces are in a yaml formated, e.g. 
the difference output from import-endnote.yaml.  The tsv file has three fields, 
the first containing the uri, the second containing the value and 
the third containing the conflicting value.  The difference are subsets 
based on the specific resource type and field (and optional subfield).

=head1 SYNOPSIS

./diff-to-tsv-all.pl [OPTIONS]

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

./diff-to-tsv-all.pl -d diff.yaml -t article -f title

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

    say "uri\tfield\tsubfield\tvalue\tother";
    for my $sub ( split ':', $subfield ) {
        for (sort keys %{ $e->{e} }) {
            my $u = $_ or next;
            $u =~ /^\/$type/ or next;
            my $r = $e->{e}->{$u};
            for (@{ $r }) {
                next unless defined $_->{$field};
                my $i = $_->{$field};
                if ($sub) {
                    next unless defined $i->{$sub};
                    $i = $i->{$sub};
                }
                my $a = defined $i->{alias} ? $i->{alias} : 'undef';
                my $b = defined $i->{value} ? $i->{value} : 'undef';
                say "$u\t$field\t$sub\t\"$a\"\t\"$b\"";
            }
        }
    }

    exit;
}
