#!/usr/bin/env perl

=head1 NAME

extract-ref.pl -- Extract references

=head1 DESCRIPTION

extract-ref.pl extracts references from a chapter.  The input is a 
google doc formated as html.  The output is a yaml file with a list of 
references for the chapter (excluding, figures, tables and findings) and the 
references for each figure, table and finding.

*** NOTE --- TABLES are not implemented ***

=head1 SYNOPSIS

./extract-ref.pl [OPTIONS]

=head1 OPTIONS

=over

=item B<--in_file>

Chapter file (from google docs html format)

=item B<--out_file>

Output file (yaml format)

=item B<--verbose>

Verbose option
ck

=head1 EXAMPLES

# link references for findings in the nca3 report

./extract-ref.pl -i chapter.html -o extract_refs.yaml

=cut

use lib './lib';

use Data::Dumper;
use Mojo::DOM::HTML;
use Path::Class qw/file/;
use Gcis::Client;
use Getopt::Long;
use YAML::XS qw/Dump/;
use Pod::Usage;

use strict;
use v5.14;
use warnings;

binmode STDOUT, ':encoding(utf8)';

GetOptions(
    'in_file=s'  => \(my $in_file),
    'out_file=s' => \(my $out_file),
    'verbose'    => \(my $verbose),
    'help|?'     => sub { pod2usage(verbose => 2) },
) or die pod2usage(verbose => 1);

pod2usage(msg => 'missing input or output file', verbose => 1) unless
    ($in_file && $out_file);

&main;

sub get_refs {
    my $s = shift;

    my %r;
    $s =~ s/&gt;/>/g;
    $s =~ s/&lt;/</g;
    my $dom = Mojo::DOM->new($s) or return 0;
    for ($dom->find('tbib')->map('text')->each) {
       my @t = split /,/, $_;
       $r{$_}++ for @t;
    }
    my $n = scalar keys %r;
    return %r ? \%r : undef;
}

sub dump_refs {
    my ($t, $a) = @_;

    return undef unless $a;
    return undef unless %{ $a };

    my $na = keys %{ $a };
    if ($verbose) {
        say "\n$t";
        say "   na : ".scalar keys %{ $a };
        say "   $_ : $a->{$_}" for sort keys %{ $a };
    }

    my %x;
    my ($ty, $n) = (split / /, $t);
    $x{type} = $ty;
    $x{ordinal} = $n if $n;
    $x{number} = $na;
    push @{ $x{references} }, $_  for sort keys %{ $a };
    # say " a :\n".Dumper(%x);

    return %x ? \%x : undef;
}

sub main {

    my $if = file($in_file)->slurp or die 'can not slurp file';
    my $dom = Mojo::DOM->new($if) or die 'can not parse file';
    my $n = 0;
    my %r_ch;
    my %r_fn;
    my $in_fn = 0;
    my $nfn;
    my %r_fg;
    my $in_fg = 0;
    my $nfg;
    my $in_cp = 0;
    for (@{ $dom->at('body')->children }) {
        $n++;
        my $s = $_->to_string;
        say " $n : $s" if $verbose;

        if ($s =~ />Key Finding \d+[\.:] *</) {
            ($nfn) = ($s =~ />Key Finding (\d+)[\.:] *</);
            $in_fn = 1;
        } elsif ($s =~ />Figure [A-Z]{0,2}\d+[\.:] /) {
            ($nfg) = ($s =~ />Figure [A-Z]{0,2}(\d+)[\.:] /);
            $in_fg = 1;
        } elsif ($s =~ />.{0,2}Introduction *</) {
            $in_fn = 0;
            $in_fg = 0;
        }

        $a = \%r_ch;
        if ($in_fg) {
           $in_fn = 0;
           $in_cp = 1 if $s =~ />Caption: *</;
           $a = \%{ $r_fg{$nfg} };
        } elsif ($in_fn) {
           die "finding in figure" if $in_fg;
           $a = \%{ $r_fn{$nfn} };
        }

        if ($verbose) {
            say " ** in fn $nfn **" if $in_fn;
            say " ** in fg $nfg **" if $in_fg;
            say " ** in cp **" if $in_cp;
        }

        if ($s =~ /tbib/) {
            my $r = get_refs($s);
            if ($r) {
                 $a->{$_} += $r->{$_} for keys %{ $r };
            }
        }
        if ($in_cp) {
            if ($in_fg) {
                $in_fg = 0;
            } else {
                die "caption outside of figure or table";
            }
            $in_cp = 0;
        }
    }

    my @y;
    my $d = dump_refs('chapter', \%r_ch);
    push @y, $d if $d;

    for (sort keys %r_fn) {
        my $d = dump_refs("finding $_", $r_fn{$_}) or next;
        push @y, $d;
    }

    for (sort keys %r_fg) {
        my $d = dump_refs("figure $_", $r_fg{$_}) or next;
        push @y, $d;
    }

    open my $of, '>:encoding(UTF-8)', $out_file or 
        die "can't open output file";;
    say $of Dump(\@y);
    close $of;
 
    return 1;
}

