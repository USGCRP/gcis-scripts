#!/usr/bin/env perl

=head1 NAME

link-chapt.pl -- Link chapter references

=head1 DESCRIPTION

link-chapt.pl links references for a chapter.

=head1 SYNOPSIS

./link-chapt.pl [OPTIONS]

=head1 OPTIONS

=over

=item B<--url>

GCIS url, e.g. http://data-stage.globalchange.gov

=item B<--file>

Input file with chapter references (see output from extract-ref.pl)

=item B<--report>

Report identifier, e.g. nca3

=item B<--chapter>

Chapter identifier, e.g. our-changing-climate

=item B<stdout>

Various log information is written to 'stdout'

=item B<--update_all>

Update all (including figures, findings, etc. in report)

=item B<--add_report>

Add references to report

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

./link-chapt.pl -u http://data-stage.globalchange.gov \
                -f extract_ref.yaml \
                -r nca3 -c our-changing-climate


=cut

use lib './lib';

use Data::Dumper;
use Mojo::DOM::HTML;
use Gcis::Client;
use YAML::XS qw/Load/;
use Getopt::Long;
use Pod::Usage;

use strict;
use v5.14;
use warnings;

GetOptions(
    'url=s'         => \(my $url),
    'file=s'        => \(my $file), 
    'report=s'      => \(my $report), 
    'chapter=s'     => \(my $chapter), 
    'update_all'    => \(my $update_all), 
    'add_report'    => \(my $add_report), 
    'max_updates=i' => \(my $max_updates = 10),
    'verbose'       => \(my $verbose),
    'dry_run|n'     => \(my $dry_run),
    'help|?'        => sub { pod2usage(verbose => 2) },
) or die pod2usage(verbose => 1);

pod2usage(msg => 'missing url, file, report or chapter', verbose => 1) unless 
    ($url && $file && $report && $chapter);

say " link chapter references";
say "   url : $url";
say "   file : $file";
say "   report : $report";
say "   chapter : $chapter";
say "   update_all $update_all" if $update_all;
say "   add_report: $add_report" if $add_report;
say "   max_updates: $max_updates" if $max_updates > 0;
say "   verbose" if $verbose;
say "   dry_run" if $dry_run;
say '';

my $n_updates = 0;
my %stats;

&main;

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
            say " already exists $r :\n   $u";
            $stats{already_exists}++;
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

    open my $f, '<:encoding(UTF-8)', $file or die "can't open file : $file";
    my $yml = do { local $/; <$f> };
    close $f;
    my $y = Load($yml);

    my $u = "/report/$report/chapter/$chapter";
    my $c = $g->get($u) or 
        die " unable to get chapter $chapter for report $report";

    my $r_uri = "/report/$report";
    my $c_uri = $c->{uri};
    say " report and chapter exist : $c_uri";
    say "";

    for (@{ $y }) {
        if (!$update_all) {
            next unless $_->{type} eq 'chapter';
        }
        my $n = $_->{references};
        
        for (@{ $n }) {
            add_ref($g, $c_uri, $_);
            add_ref($g, $r_uri, $_) if $add_report;
            last if $max_updates > 0 && $n_updates >= $max_updates;
        } 
    }

    say "\n n update : $n_updates";
    for (sort keys %stats) {
        say "   $_ : $stats{$_}";
    }

    return;
}
