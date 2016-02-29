#!/usr/bin/env perl

=head1 NAME

import-yaml.pl -- Import items into GCIS from a yaml file

=head1 DESCRIPTION

import-yaml.pl imports items into GCIS from a yaml formated file.  The 
input file can be created by export-yaml.pl.

If the item currently exists in GCIS it is not imported.  Any differences 
an existing item and the new item is displayed.

Note that any relationships are not updated.

*** This program has only been tested with "findings". ***

=head1 SYNOPSIS

./import-yaml.pl [OPTIONS]

=head1 OPTIONS

=over

=item B<--url>

GCIS url, e.g. http://data-stage.globalchange.gov

=item B<--file>

Input yaml formatted file with GCIS items

=item B<stdout>

Various log information is written to 'stdout'

=item B<--max_updates>

Maximum number of entries to update (defaults to 10;
set to -1 update all)

=item B<--dry_run> or B<--n>

Dry run option

=back

=head1 EXAMPLES

# add a set of findings to GCIS from an yaml file:

./import-yaml.pl -u http://data-stage.globalchange.gov \
                 -f findings.yaml

=cut

use Data::Dumper;
use Gcis::Client;
use Clone::PP qw(clone);
use YAML::XS;
use Getopt::Long;
use Pod::Usage;

use strict;
use v5.14;
use warnings;

binmode STDOUT, ':encoding(utf8)';

GetOptions(
    'url=s'          => \(my $url),
    'file=s'         => \(my $file),
    'max_updates=i'  => \(my $max_updates = 10),
    'dry_run|n'      => \(my $dry_run),
    'help|?'         => sub { pod2usage(verbose => 2) },
) or die pod2usage(verbose => 1);

pod2usage(msg => "missing url or yaml file", verbose => 1) 
    unless ($url && $file);

my $n_updates = 0;

say " importing items from yaml file";
say "   url : $url";
say "   file : $file";
say "   max_updates : $max_updates";
say "   dry_run" if $dry_run;
say '';

&main;

sub load_yaml {
    my $file = shift or return undef;
    open my $f, '<:encoding(UTF-8)', $file or die "can't open file : $file";

    my $yml = do { local $/; <$f> };
    my $y = Load($yml);
    return $y;
}

sub compare_hash {
    my ($a, $b, @i) = @_;

    my %i1 = map { $_ => 1 } @i;
    my %c;
    for (keys %{ $a }) {
        next if $i1{$_};
        next if !$a->{$_}  &&  !$b->{$_};
        if (!$b->{$_}) {
           $c{$_} = {_A_ => $a->{$_}, _B_ => undef};
           next;
        }
        if (!$a->{$_}) {
           $c{$_} = {_A_ => undef, _B_ => $b->{$_}};
           next;
        }
        if (ref $a->{$_} eq 'HASH') {
            my $c1 = compare_hash($a->{$_}, $b->{$_}, @i) or next;
            $c{$_} = $c1;
            next;
        }
        next if $a->{$_} eq $b->{$_};
        $c{$_} = {_A_ => $a->{$_}, _B_ => $b->{$_}};
    }
    return %c ? \%c : undef;

    return 1;
}

sub dump_diff {
    my ($d, $s) = @_;

    $s = $s ? $s.'  ' : '   ';
    for (sort keys %{ $d }) {
        my $x = $d->{$_};
        if (!grep '_A_' eq $_, keys %{ $x }) {
            dump_diff($s, $s) for sort keys %{ $x };
            next;
        }
        say "$s$_ : ";
        say "$s  new     : $x->{_A_}";
        say "$s  current : $x->{_B_}";
    }
    return 1;
}

sub add_item {
    my ($g, $j) = @_;

    my $u = $j->{uri};

    if ($dry_run) {
        say " would add : $u";
        $n_updates++;
        return 1;
    }

    say " adding : $u";
    my $n = clone($j);
    delete $n->{$_} for qw(uri href);;
    my ($a) = ($u =~ /^(.+)\//);
    $n_updates++;
    $g->post($a, $n) or die " unable to add : $u";

    return 1;
}


sub main {
    my $l = load_yaml($file);
    my $g = $dry_run ? Gcis::Client->new(url => $url) :
                       Gcis::Client->connect(url => $url);

    my $ignore = qw(href);
    my $n = @{ $l };
    say " number of items read : $n";
    for my $x (@{ $l }) {
        my $u = $x->{uri};
        say " ";
        say " uri : $u";
        my $c = $g->get($u);
        if ($c) {
            say " already exists";
            my $ignore = qw(href);
            my $d = compare_hash($x, $c, $ignore);
            if (!$d) {
               say " same";
               next;
            }
            say " different :";
            dump_diff($d);
            next;
        }
        add_item($g, $x);
        last unless $max_updates < 0  ||  $n_updates < $max_updates;
    }
    
    exit;
}
