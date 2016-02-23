#!/usr/bin/env perl

use Data::Dumper;
use Gcis::Client;
use CrossRef;

use strict;
use v5.14;
use warnings;

my $url = "https://data.gcis-dev-front.joss.ucar.edu";
my $dry_run = 0;
my $max_updates = -1;
my $do_all = 1;

&main;

sub main {
    my $g = $dry_run ? Gcis::Client->new(url => $url)
                     : Gcis::Client->connect(url => $url);
    my $cr = CrossRef->new;

    my $v = "/article";
    $v .= "?all=1" if $do_all;
    my @l = $g->get($v) or die " unable to get articles";
    my $n = @l;
    say " articles : $n\n";
    my $n_updates = 0;
    for my $a (@l) {
        last if $max_updates > -1  &&  $n_updates >= $max_updates;
        next unless $a->{doi};
        my $u = $a->{uri};
        next if $a->{journal_vol}  &&  $a->{journal_pages};
        my $c = $cr->get($a->{doi}) or do {
            say " doi not in crossref : $u";
            next;
        };
        if (!$c->{title}) {
            say " title not in crossref : $u";
            next;
        }
        if (lc $a->{title} ne lc $c->{title}) {
            say " titles do not match : $u";
            say "   gcis     : $a->{title}";
            say "   crossref : $c->{title}";
            next;
        }
        my %check = (
            journal_vol => qw(^\d+),
            journal_pages => qw(^\d+-\d+$),
        );
        my $new = 0;
        for (qw(journal_vol journal_pages)) {
           next unless $c->{$_};
           next unless $c->{$_} =~ /$check{$_}/;
           if ($a->{$_}) {
               next if $a->{$_} eq $c->{$_};
           }
           $a->{$_} = $c->{$_};
           $new++;
        }
        next unless $new;

        if ($dry_run) { 
            say " would update : $u";
            $n_updates++;
            next;
        }

        say " updating : $u";
        delete $a->{$_} for qw(uri href);
        $n_updates++;
        $g->post($u, $a) or die " unable to add : $u";
    }

    say "\n number updates : $n_updates";

    return;
}
