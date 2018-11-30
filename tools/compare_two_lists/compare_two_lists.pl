#!/usr/bin/env perl

=head1 NAME

compare_two_lists.pl -- find lines in A not in B

=head1 DESCRIPTION

Find all lines in file A not present in file B.

=head1 SYNOPSIS

./compare_two_lists.pl --afile file.txt --bfile another.txt

=head1 OPTIONS

=over

=item B<--afile>

The first file, used as the source

=item B<--bfile>

The second file, used as the compare

=item B<--verbose>

Verbose option

=back

=head1 EXAMPLES


  ./compare_two_files.pl \
    --afile foo.txt \
    --bfile bar.txt

=cut

use Getopt::Long qw/GetOptions/;
use Pod::Usage qw/pod2usage/;

use strict;
use v5.14;

GetOptions(
  'afile=s'      => \(my $file_a),
  'bfile=s'      => \(my $file_b),
  'verbose'      => \(my $verbose),
  'help|?'       => sub { pod2usage(verbose => 2) },
) or die pod2usage(verbose => 1);

pod2usage(msg => "missing file_a", verbose => 1) unless $file_a;
pod2usage(msg => "missing file_b", verbose => 1) unless $file_b;


my $source = load_file($file_a);
my $compare = load_file($file_b);

&main;

sub main {

    say "Finding lines in one file missing from the other";
    say " file_a : $file_a";
    say " file_b : $file_b";
    say " verbose on" if $verbose;


    my $remainder;
    for my $line ( @$source ){
        $remainder->{$line}=1;
    }
    for my $source_line ( @$source ) {
        say "Checking '$source_line' " if $verbose;
        for my $compare_line ( @$compare ) {
            if ( $source_line eq $compare_line ) {
                say "    - Found matching '$compare_line'" if $verbose;
                delete $remainder->{$source_line};
            }
        }
    }

    say "Unmatched lines:";
    for my $key ( keys %$remainder ) {
        say $key;
    }
}

sub load_file {
    my $file = shift;


    open my $handle, '<', $file;
    chomp(my @lines = <$handle>);
    close $handle;

    return \@lines;
}

