#!/usr/bin/env perl

=head1 NAME

check-urls.pl -- Check to see if URLs are valid in GCIS.

=head1 DESCRIPTION

This is a long running script!!!

Given a type, this script goes and asks
GCIS for every item of that type and
then checks each URL for its response
and possible redirect URL.

Output can be saved to a file and viewed
in excel.

=head1 SYNOPSIS

./check-urls.pl [OPTIONS]

=head1 OPTIONS

=over

=item B<--url>

GCIS url, default: http://data-stage.globalchange.gov

=item B<--page>

Starting page, default 1.

=item B<--count>

How many pages to process (each page is 20 objects).

=itemB<--all>

Just process all of an item (warning - really long in some cases)

=item B<--type>

A GCIS type. Valid options:

=over

=item I<article>

=item I<book>

=item I<dataset>

=item I<figure>

=item I<finding>

=item I<journal>

=item I<organization>

=item I<person>

=item I<report>

=item I<table>

=back

=back

=head1 EXAMPLES

    # ask stage for all the reports
    ./check-urls.pl --type report --all  >gcis_report_url_codes.tsv

    # get the first 100 articles
    ./check-urls.pl --type article --page 1 --count 5 >gcis_articles_1-100_url_codes.tsv

    # get the next 100 articles
    ./check-urls.pl --type article --page 6 --count 5 >gcis_articles_101-200_url_codes.tsv

=cut

use v5.20;
use Mojo::UserAgent;
use Gcis::Client;
use Data::Dumper;
use Getopt::Long qw/GetOptions/;
use Pod::Usage;

my %TYPES = (
    article => 1,
    book => 1,
    report => 1,
    figure => 1,
    table => 1,
    journal => 1,
    finding => 1,
    dataset => 1,
    person => 1,
    organization => 1,
);

GetOptions(
    'url=s'              => \(my $url),
    'type=s'             => \(my $type),
    'page=i'             => \(my $page),
    'count=i'            => \(my $count),
    'all!'               => \(my $all),
    'help|?'             => sub { pod2usage(verbose => 2) },
) or die pod2usage(verbose => 1);

pod2usage(msg => "missing type", verbose => 1) unless $type;
pod2usage(msg => "missing count & page or all", verbose => 1) unless ($all || ( $count && $page) );
pod2usage(msg => "Bad type, select from: " . join(", ", keys %TYPES), verbose => 1) unless $TYPES{$type};

$url = "https://data-stage.globalchange.gov" unless $url;

$count = 1 if $all;

warn "Processing " . $count * 20 . " URL queries. Expect this script to run for " . ($count * 20 / 60) . " to " . ($count * 20 * 3 / 60) . " minutes." unless $all;
say "Resource\tURL\tResponse\tRedirect URL";
while ( $count > 0)
{
    my $g = Gcis::Client->new(url => $url);
    my $ua = Mojo::UserAgent->new;
    my $query = $all
        ? "/$type?all=1"
        : "/$type?page=$page";
    my $resources = $g->get($query);

    my $res_count = scalar @$resources;
    warn "Processing $res_count URL queries. Expect this script to run for " .  ($res_count / 60) . " to " . ($res_count * 3 / 60) . " minutes." if $all;
    my $index = 0;
    for my $resource ( @$resources ) {
        my $resource_url = $resource->{url} ? $resource->{url} : "";

        my $code = "";
        my $redirect = "";
        if ( $resource_url ) {
            my $res = $ua->get($resource_url)->result;
            $code = $res->code;
            $redirect = $res->headers->location if $code =~ /^3/;
        }
        say "$resource->{href}\t$resource_url\t$code\t$redirect";
        $index++;
        sleep 1 unless $index % 5;
    }

    $count--;
    $page++;
}

1;
