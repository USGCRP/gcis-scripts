#!/usr/bin/env perl

=head1 NAME

connect_publications_to_regions.pl -- Connect publications and regions

=head1 DESCRIPTION

connect_publications_to_regions.pl - Given a region GCIS ID and a resource URI,
the resource is connected to the region.

=head1 SYNOPSIS

./connect_publications_to_regions.pl [OPTIONS]

=head1 OPTIONS

=over

=item B<--url>

GCIS url to work against, e.g. http://data-stage.globalchange.gov

=item B<--input_file>

plaintext file in the format:

region_uri_1 resource_uri_1
region_uri_1 resource_uri_2
region_uri_2 resource_uri_1
...

=item B<stdout>

Various log information is written to 'stdout'

=item B<--wait>

Time to wait between GCIS updates (seconds; defaults to -1 - do not wait)

=item B<--dry_run> or B<--n>

Dry run option

=back

=head1 EXAMPLES

 ./connect_publications_to_regions.pl -u http://data-stage.globalchange.gov \
                                     -i regions.txt

=cut

use lib './lib';

use Data::Dumper;
use Gcis::Client;
use Getopt::Long;
use Pod::Usage;
use Time::HiRes qw(usleep);
use PubMed;
use Utils;

use strict;
use v5.14;
use warnings;

binmode STDIN, ':encoding(utf8)';
binmode STDOUT, ':encoding(utf8)';

GetOptions(
    'url=s'                 => \(my $url),
    'input_file=s'          => \(my $input),
    'wait=i'                => \(my $wait = -1),
    'dry_run|n'             => \(my $dry_run),
    'help|?'                => sub { pod2usage(verbose => 2) },
) or die pod2usage(verbose => 1);

pod2usage(msg => "missing url or input file", verbose => 1) unless ($url && $input);

&main;

# Given a GCIS Handle, a region URI and a publication URI, connect them

sub connect_uris {
    my ($gcis_handle, $connection) = @_;

    my $resource_uri = $connection->{resource};
    my $region_uri = $connection->{region};

    my $resource = $gcis_handle->get($resource_uri) or die " unable to find resource: $resource_uri";
    my $fixed_resource_uri = $resource->{uri};

    if ($region_uri !~ /region/) {
        say "ERROR: Region does not look like a region $region_uri. Resource: $fixed_resource_uri";
        return;
    }

    my ($region_id) = $region_uri =~ m[region/(.*)];
    my ($base_uri, $resource_id) = $fixed_resource_uri =~ m[(^.*)/(.*)];

    my $post_uri = "$base_uri/regions/$resource_id";
    my $post_body = { identifier => $region_id };

    if ($dry_run) {
        say "DRY RUN: Would connect region $region_uri with resource $fixed_resource_uri";
        say "         post URI: $post_uri";
        say "         post body:" . Dumper $post_body;
        return;
    }

    my $created_resource = $gcis_handle->post("$post_uri", $post_body) or die " unable to connect $region_uri : $fixed_resource_uri";
    sleep($wait) if $wait > 0;

    return;
}

sub load_file {
    open FILE, "<", $input or die $!;
    my @lines = <FILE>;
    close FILE;

    my $connections;
    for my $line ( @lines ) {
        my ( $reg, $res ) = split( ' ', $line );
        push @$connections, { region => $reg, resource => $res };
    }
    return $connections;
}

sub main {
    my %import_args;
    my $gcis = $dry_run ? Gcis::Client->new(url => $url)
                        : Gcis::Client->connect(url => $url);

    my $connections = load_file();

    foreach my $connection (@$connections ) {
        say "Connecting Region $connection->{region} to Resource $connection->{resource}";
        connect_uris($gcis, $connection);
    }

    return;
}
