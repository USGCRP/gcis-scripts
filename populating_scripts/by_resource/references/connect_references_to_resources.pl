#!/usr/bin/env perl

=head1 NAME

connect_references_to_resources.pl -- Connect a reference and resource

=head1 DESCRIPTION

connect_references_to_resources.pl - Given a reference URI and a resource URI,
the resource is connected as containing the reference.

This program does not create the reference.

For report imports, the import-endnote-to-references.pl script outputs a
references created file
that can inform this input.

=head1 SYNOPSIS

./connect_references_to_resources.pl [OPTIONS]

=head1 OPTIONS

=over

=item B<--url>

GCIS url to work against, e.g. http://data-stage.globalchange.gov

=item B<--input_file>

plaintext file in the format:

reference_uri_1 resource_uri_1
reference_uri_1 resource_uri_2
reference_uri_2 resource_uri_1
...

=item B<stdout>

Various log information is written to 'stdout'

=item B<--wait>

Time to wait between GCIS updates (seconds; defaults to -1 - do not wait)

=item B<--verbose>

Verbose option

=item B<--dry_run> or B<--n>

Dry run option

=back

=head1 EXAMPLES

./connect_references_to_resources.pl -u http://data-stage.globalchange.gov \
                                     -i ref_to_resource.pl

=cut

use lib './lib';

use Data::Dumper;
use Gcis::Client;
use YAML::XS;
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
    'verbose'               => \(my $verbose),
    'dry_run|n'             => \(my $dry_run),
    'help|?'                => sub { pod2usage(verbose => 2) },
) or die pod2usage(verbose => 1);

pod2usage(msg => "missing url or input file", verbose => 1) unless ($url && $input);

&main;

# Given a GCIS Handle, a reference URI and a publication URI, connect them

sub connect_uris {
    my ($gcis_handle, $connection) = @_;

    my $resource_uri = $connection->{resource};
    my $reference_uri = $connection->{reference};

    if ($reference_uri !~ /reference/) {
        say "ERROR: Reference does not look like a reference: $reference_uri. Resource: $resource_uri";
        return;
    }

    my ($reference_uuid) = $reference_uri =~ m[reference/(.*)];

    if ($dry_run) {
        say "DRY RUN: Would connect reference $reference_uri (UUID: $reference_uuid) with resource $resource_uri";
        return;
    }

    my $post_uri = "/reference/rel/" . $reference_uuid;
    my $post_body = { add_publication_uri => $resource_uri };
    my $created_resource = $gcis_handle->post("$post_uri", $post_body) or die " unable to connect $reference_uri : $resource_uri";
    sleep($wait) if $wait > 0;

    return;
}

sub load_file {
    open FILE, "<", $input or die $!;
    my @lines = <FILE>;
    close FILE;

    my $connections;
    for my $line ( @lines ) {
        my ( $ref, $res ) = split( ' ', $line );
        push @$connections, { reference => $ref, resource => $res };
    }
    return $connections;
}

sub main {
    my %import_args;
    my $gcis = $dry_run ? Gcis::Client->new(url => $url)
                        : Gcis::Client->connect(url => $url);

    my $connections = load_file();

    foreach my $connection (@$connections ) {
        say "Connecting Reference $connection->{reference} to Resource $connection->{resource}";
        connect_uris($gcis, $connection);
    }

    return;
}
