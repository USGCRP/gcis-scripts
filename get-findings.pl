#!/usr/bin/env perl

=head1 NAME

!!! need to update this !!!

add-urls.pl -- Add a list of urls to GCIS.

=head1 SYNOPSIS

./add-urls.pl [OPTIONS]

=head1 OPTIONS

=over

=item B<--url>

GCIS url, e.g. http://data-stage.globalchange.gov

=item <stdin>

List of uri/url pairs to add (comma separated, one per line)
   Note: use "#" at start of line to denote a commment (not deleted)

=item B<--max_update>

Max update (default = 10)
 
=item B<--dry_run> or B<--n> 

Dry run

=back

=head1 EXAMPLES

# add a set of urls from a list

./add-urls.pl -u http://data-stage.globalchange.gov < url_list.txt

=cut

use Gcis::Client;
use Getopt::Long qw/GetOptions/;
use Pod::Usage;
use Data::Dumper;
use strict;
use v5.14;

GetOptions(
    'url=s'	=> \(my $url),
    'max_updates=i' => \(my $max_updates = 10),
    'dry_run|n' => \(my $dry_run),
    'help|?'	=> sub { pod2usage(verbose => 2) },
) or die pos2usage(verbose => 1);

# pod2usage(msg => "missing url", verbose => 1) unless $url;

my $r_url = "http://nca2014.globalchange.gov/report";
my $url = "https://data.gcis-dev-front.joss.ucar.edu";
my $report = "nca3";

{
    my $ua = Mojo::UserAgent->new();
    my $a = Gcis::Client->new(url => $url);
    say " here!";

    my $n_updates = 0;
#    say " adding urls";
#    say "     url : $url";
#    say "     max_updates : $max_updates";
#    say "     dry run" if $dry_run;

    my @c = $a->get("/report/$report/chapter");
    my $n = 0;
    my $n_max = 10;
    for (@c) {
        $n++;
        last if $n > $n_max;
        my $u = $_->{uri};
        my $o = $a->get($_->{uri});
        # say " o :".Dumper($o);
        my $i = $o->{identifier};
        my $cn = $o->{number};
        my $cu = $o->{url};
        say " n : $n, i : $i, cn : $cn, cu : $cu";
        next unless $cu;
        next unless $cn == 3;
        my $h = `curl -s $cu`;
        my $d = Mojo::DOM->new($h);
        # say " d :".Dumper($d);
        my @m = map { $_ } $d->find('article')->each;
        for (@m) {
            my $p = $_->find('span');
            say " p :".Dumper($p);
            last;
        }
    }
    exit;

    while (<>) {
       chomp;
       my ($uri, $u) = split ",";
       if (!($uri =~ /^\//)) { 
           $uri = "/".$uri;
       }
       say " uri : $uri";
       say "     - url: $u";
       if ($uri =~ /^# /) {
           say "     - skipping uri";
           next;
       }
       my $f = $uri;
       $f =~ s[/figure/][/figure/form/update/] if !$dry_run;
       # say " f : $f";
       my $r = $a->get($f);
       if (!$r) {
           say "     - does not exist";
           next;
       }
       # say "   r :\n".Dumper($r);
       # say " current url value: $r->{url}";
       if ($r->{url}) {
           if ($r->{url} eq $u) {
              say "     - urls match, skipping";
           } else {
              say "     - url already has a value, skipping";
           }
           next;
       }       
       if ($dry_run) {
           say "     - would add url";
           next;
       }
       $r->{url} = $u;
       $a->post($uri, $r) or 
           say "     ** update error **";
       say  "     - added url";
       $n_updates++;  
       last if $n_updates >= $max_updates;
    } 
    say " done";
}

1;

