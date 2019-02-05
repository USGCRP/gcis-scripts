#!/usr/bin/env perl

=head1 NAME

check-amazon-ip-range.pl -- Check to see what amazon URLs have changed

=head1 DESCRIPTION

Pulls the newest Amazon IP Range and compares with the existing one.

=head1 SYNOPSIS

./check-amazon-ip-range.pl [OPTIONS]

=head1 OPTIONS

=over

=item B<--old_amazon_data>

The existing Amazon data file

=item B<--new_amazon_data>

The new Amazon data file will be saved here

=item B<--diff>

JSON file with the differing entries

=item B<--verbose>

Whether or not to explain in the command line

=back

=head1 EXAMPLES

    ./check-amazon-ip-range.pl --old existing_amazon_ips.json --new new_amazon_ips.json --diff changes_amazon_ips.json

=cut

use v5.20;
use Mojo::UserAgent;
use Gcis::Client;
use Data::Dumper;
use JSON::XS;
use Getopt::Long qw/GetOptions/;
use Pod::Usage;

GetOptions(
    'old_amazon_data=s' => \(my $old_file),
    'new_amazon_data=s' => \(my $new_file),
    'diff=s'            => \(my $diff_file),
    'verbose!'          => \(my $verbose),
    'help|?'            => sub { pod2usage(verbose => 2) },
) or die pod2usage(verbose => 1);

pod2usage(msg => "missing old amazon file", verbose => 1) unless $old_file;
pod2usage(msg => "missing new amazon file", verbose => 1) unless $new_file;
pod2usage(msg => "missing diff amazon file", verbose => 1) unless $diff_file;

my $url = "https://ip-ranges.amazonaws.com/";
#my $amazon = Gcis::Client->new->url($url)->accept("application/json");
#my $results = $amazon->get();
my $new_ips = Gcis::Client->new->url($url)->accept("application/json")->get("ip-ranges.json");

my $old_json = do {
    local $/ = undef;
    open my $fh, "<", $old_file
        or die "could not open $old_file: $!";
    <$fh>;
};
my $old_ips = decode_json $old_json;

if ($old_ips->{createDate} eq $new_ips->{createDate} ) {
    say "Create Dates haven't changed. Not checking";
    exit;
}

my $diff_entries;
for my $new_entry ( @{$new_ips->{prefixes}} ) {
    my $found = 0;
    for my $old_entry ( @{$old_ips->{prefixes}} ) {
        if ( $new_entry->{ip_prefix} eq $old_entry->{ip_prefix} && $new_entry->{region} ne $old_entry->{region} && $new_entry->{service} ne $old_entry->{service} ) {
            $found = 1;
            last;
        }
    }
    if ( ! $found ) {
        say "New Entry: $new_entry->{ip_prefix} $new_entry->{service} $new_entry->{region}";
        push @{$diff_entries->{new}}, $new_entry;
        last;
    }
}

for my $old_entry ( @{$old_ips->{prefixes}} ) {
    my $found;
    for my $new_entry ( @{$new_ips->{prefixes}} ) {
        if ( $new_entry->{ip_prefix} eq $old_entry->{ip_prefix} && $new_entry->{region} ne $old_entry->{region} && $new_entry->{service} ne $old_entry->{service} ) {
            $found = 1;
            last;
        }
    }
    if ( ! $found ) {
        say "Deleted Entry: $old_entry->{ip_prefix} $old_entry->{service} $old_entry->{region}";
        push @{$diff_entries->{deleted}}, $old_entry;
        last;
    }
}

my $diff_json = encode_json $diff_entries;
my $new_json = encode_json $new_ips;

open(my $fh, '>', $diff_file) or die "Could not open file '$diff_file' $!";
print $fh $diff_json;
close $fh;

open(my $fh2, '>', $new_file) or die "Could not open file '$new_file' $!";
print $fh2 $new_json;
close $fh2;

1;
