#!/usr/bin/env perl

=head1 NAME

link-ref.pl -- Link references

=head1 DESCRIPTION

link-ref.pl links references for a type of resource in a report.

=head1 SYNOPSIS

./link-ref.pl [OPTIONS]

=head1 OPTIONS

=over

=item B<--url>

GCIS url, e.g. http://data-stage.globalchange.gov

=item B<--report>

Report identifier, e.g. nca3

=item B<--what>

Resource to check, e.g. finding

=item B<stdout>

Various log information is written to 'stdout'

=item B<--max_updates>

Maximum number of entries to update (defaults to 10;
set to -1 update all)

=item B<--verbose>

Verbose option

=item B<--dry_run> or B<--n>

Dry run option

=back

=head1 EXAMPLES

# link references for findings in the nca3 report

./link-ref.pl -u http://data-stage.globalchange.gov
              -r nca3 -w finding


=cut

use lib './lib';

use Data::Dumper;
use Mojo::DOM::HTML;
use Gcis::Client;
use Getopt::Long;
use Pod::Usage;

use strict;
use v5.14;
use warnings;

GetOptions(
    'url=s'         => \(my $url),
    'report=s'      => \(my $report), 
    'what=s'        => \(my $what), 
    'max_updates=i' => \(my $max_updates = 10),
    'verbose'       => \(my $verbose),
    'dry_run|n'     => \(my $dry_run),
    'help|?'        => sub { pod2usage(verbose => 2) },
) or die pod2usage(verbose => 1);

pod2usage(msg => 'missing url, report or what', verbose => 1) unless 
    ($url && $report && $what);

grep $what eq $_, qw(finding figure table) or 
    die " resource '$what' not implmented";

say " link references";
say "   url : $url";
say "   report : $report";
say "   what : $what";
say "   max_updates: $max_updates";
say "   verbose" if $verbose;
say "   dry_run" if $dry_run;
say '';

my $n_updates = 0;
my %stats;

&main;

sub get_refs {
    my $f = shift;

    my @l = qw(confidence process uncertainties evidence 
               caption source_citation);
    my %r;
    for (@l) {
        next unless $f->{$_};
        my $dom = Mojo::DOM->new($f->{$_}) or next;
        $r{$_}++ for $dom->find('tbib')->map('text')->each;
    }
    
    return %r ? \%r : undef;
}

sub fix_identifier {
    my $r = shift;

    my $id = 'child_publication';
    return 1 unless $r->{$id};
    my %list = (
        '%3C' => '<', '%3E' => '>', 
        '%5B' => '[', '%5D' => ']',
        );
    for (keys %list) {
        $r->{$id} =~ s/$_/$list{$_}/g;
    }

    return 1;
}

sub add_ref {
    my ($g, $u, $r) = @_;
    my $r1 = $g->get("/reference/$r") or do {
        say " not found $r :\n   $u";
        $stats{not_found}++;
        return 0; 
    };
    for (@{ $r1->{publications} }) {
        if ($u eq $_) {
            say " already exists b $r :\n   $u";
            $stats{already_exists_b}++;
            return 0;
        }
    }
    if ($dry_run) {
        say " would add $r :\n   $u";
        $stats{would_add}++;
        $n_updates++;
        return 1;
    }
    say " adding $r :\n   $u";
    delete $r1->{$_} for qw(uri href publications);
    $r1->{publication} = $u;
    fix_identifier($r1);
    $n_updates++;
    $g->post("/reference/$r", $r1) or 
        die " upable to add $r :\n   $u";
    $stats{added}++;

    return 1;
}

sub main {
    my $g = $dry_run ? Gcis::Client->new(url => $url)
                     : Gcis::Client->connect(url => $url) or 
        die " unable to connect to $url";

    my $all = "?all=1";
    my $f = $g->get("/report/$report/$what$all") or 
        die " unable to get $what for $report";
    my $nf = @{ $f };
    say " number of $what(s) : $nf\n";

    for (@{ $f }) {
        my $uri = $_->{uri} or do {
            say " no uri";
            next;
        };
        say "\n $what : $_->{uri}";
        my %exists; 
        for (@{ $g->get("$uri/reference") }) {
            $exists{$_->{identifier}} = 1;
        }

        my $check = get_refs($_);
        for (sort keys %{ $check }) {
            if ($exists{$_}) {
               say " already exists a $_ :\n   $uri";
               $stats{already_exists_a}++;
               next;
            }
            add_ref($g, $uri, $_);
            last if $max_updates > 0 && $n_updates >= $max_updates;
        } 
        last if $max_updates > 0 && $n_updates >= $max_updates;
    }

    say "\n n update : $n_updates";
    for (sort keys %stats) {
        say "   $_ : $stats{$_}";
    }

    return;
}
