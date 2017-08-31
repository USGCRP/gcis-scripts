#!/usr/bin/env perl

=head1 NAME

tsv-to-diff.pl -- Convert tsv file to a difference file

=head1 DESCRIPTION

tsv-to-diff.pl reads a file in tsv (tab separated value) format and outputs 
the difference yaml format.  The tsv file has three or four fields, 
the first containing the uri, the second containing the value and 
the third containing the conflicting value. The optional forth field contains
a flag indicating whether the given value (second field) is okay.

The main purpose of this script is to create a errata file based on the 
output of a spreadsheet.  The script diff-to-tsv.pl can be used to 
create the input for the spreadsheet analysis.

There is a single header row describing the fields.  The first field in the 
header contains 'uri' followed by the field and optional subfield 
(separated by spaces).  Note, only one resource type, field and optional 
subfield combination should be provide.

=head1 SYNOPSIS

./tsv-to-diff.pl [OPTIONS]

=head1 OPTIONS

=over

=item B<--file>

Input file (tsv format)

=item B<stdout>

Differences (errata) in yaml format

=item B<--okay_flag>

Flag value in fouth field that indicates that the value field is okay 
(e.g. endnote)

=back

=head1 EXAMPLES

# convert the differnece and use 'endnote' as the flag to say the diff is okay

./tsv-to-diff.pl -f diff.tsv -o endnote

=cut

use Data::Dumper;
use YAML::XS;
use Getopt::Long;
use Pod::Usage;

use strict;
use v5.14;
use warnings;

binmode STDOUT, ':encoding(utf8)';

GetOptions(
    'file=s'      => \(my $file),
    'okay_flag=s' => \(my $okay_flag),
    'help|?'      => sub { pod2usage(verbose => 2) },
) or die pod2usage(verbose => 1);

pod2usage(msg => "missing file", verbose => 1)
    unless $file;

&main;

sub main {

    open my $f, '<:encoding(UTF-8)', $file or die "can't open file : $file";
    chomp(my @tsv = <$f>);
    close $f;

    my $n = @tsv;
    $n > 0 or die "empty file : $file";

    my @h = split '\t', $tsv[0];
    my $mh = @h;
    $mh >= 3 or do {
        say " line 1 - $tsv[0]";
        die "less than three fields in header : $mh";
    };

    my ($x, $field, $subfield) = split ' ', $h[0];
    $x eq 'uri' or do {
        say " line 1 - $tsv[0]";
        die "header - first value is not 'uri' : $x";
    };
    $field or do {
        say " line 1 - $tsv[0]";
        die "header - second value (field) is not given";
    };


    my $l = 0;
    my $o;
    shift @tsv;
    for (@tsv) {
        $l++;
        my @d = split '\t';
        my $m = @d;
        $m >= 3 or do {
            say " line $l - $_";
            die "less than 3 fields in difference : $m\n";
        };
        $m <= $mh or do {
            say " line $l - $_";
            die "too many fields in difference : $m > $mh";
        };
        my $v->{uri} = shift @d;
        my $c->{item} = $subfield ? $subfield : $field;
        $c->{alias} = shift @d;
        $c->{value} = shift @d;
        if ($m > 3) {
            $c->{value} = '_DIFF_OKAY_' if $okay_flag eq shift @d;
        }
        for (qw(alias value)) {
            $c->{$_} = undef if $c->{$_} eq 'undef';
        }
        if ($subfield) {
            my $s->{$field}->[0] = $c;
            push @{ $v->{errata} }, $s;
        } else {
            push @{ $v->{errata} }, $c;
        }
        push @{ $o }, $v;
    }

    say Dump($o);

    exit;
}
