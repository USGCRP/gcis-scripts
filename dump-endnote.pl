#!/usr/bin/env perl

use Getopt::Long qw/GetOptions/;
use Pod::Usage qw/pod2usage/;

use YAML;
use Refs;
use Data::Dumper;
use Clone::PP qw(clone);

use strict;
use v5.14;
use warnings;

binmode STDOUT, ':encoding(utf8)';

GetOptions(
  'file=s'   => \(my $file), 
  'help|?'      => sub { pod2usage(verbose => 2) },
) or die pod2usage(verbose => 1);

my $max_references = -1;
my $which = 'Report';

my $n = 0;
&main;

sub main {

    say "---";
    say "- endnote_dump: ~";
    say "  file: $file";
    say "  max_references: $max_references";
    say "";

    my $r = Refs->new;
    $r->{n_max} = $max_references;
    $r->load($file);
    my $c;
    my $o;
    for my $a (@{ $r->{records} }) {
	my $t = $a->{reftype}[0];
        if ($which) {
           next unless $t eq $which;
        }
        $c->{total}->{n}++;
        $c->{$t}->{n}++;
        
        for (keys %{ $a }) {
            if (!@{ $a->{$_} }) {
                delete $a->{$_};
                next;
            }
            $c->{$t}->{$_}++;
            $c->{total}->{$_}++;
            my $n = @{ $a->{$_} };
            next if $n > 1;
            $a->{$_} = $a->{$_}[0];
        }
        push @{ $o }, clone($a);
    }

    say Dump($o);
    say Dump($c);

    return;
}

1;

=head1 NAME

dump-endnote.pl -- dump endnote file

=head1 DESCRIPTION

dump-endnote.pl -- reads references from an endnote file in xml
format and dumps them to stdout in yaml format

=head1 SYNOPSIS

./dump-endnote.pl [OPTIONS]

=head1 OPTIONS

=over

=item B<--file>

Endnote file (xml format)

=item B<stdout>

Dump of endnote file (yaml format)

=back

=head1 EXAMPLES

Dump an endnote file to stdout in yaml format

./dump-endnote.pl --file endnote.xml > endnote.yaml

=cut
