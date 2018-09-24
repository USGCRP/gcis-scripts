#!/usr/bin/env perl

=head1 NAME

update-reference-keys.pl -- add and/or update reference key values

=head1 DESCRIPTION

update-reference-keys.pl updates references in GCIS.

If the reference key exists, the 'update' flag will determine
if the new value is applied. Keys are never removed. Reference
must already exist.

=head1 SYNOPSIS

./update-reference-keys.pl [OPTIONS]

=head1 OPTIONS

=over

=item B<--url>

GCIS url, e.g. https://data-stage.globalchange.gov

=item B<--file>

File containing the references with keys to update

=item B<--update>

Whether to overwrite existing key values or only add the new ones

=item B<--verbose>

Verbose option

=item B<--dry_run>

Set to perform dry run (no actual update)

=back

=head1 EXAMPLES

# Only add new keys
./update-reference-keys.pl \
  --url https://data-stage.globalchange.gov \
  --file refs.yaml

# Add new keys and update existing ones
./update-reference-keys.pl \
  --url https://data-stage.globalchange.gov \
  --file refs.yaml \
  --update

Example input file (yaml format):

  ---
  - uri: /reference/00ba60eb-88b2-4ca5-860d-1af87a8becb2
    ISSN: 1234-4312
  - uri: /reference/06df11af-a2ec-4d3b-9d7a-acf9783e1e4f
    ISSN: 1234-4312
    Year: 2013
  - uri: /reference/9e08d11c-6cbc-4531-8cb3-80f5b81fabb1
    ISSN: 1234-4312

=cut

use Getopt::Long qw/GetOptions/; use Pod::Usage qw/pod2usage/;

use Gcis::Client; use YAML::XS; use Data::Dumper; use Clone::PP qw(clone);

use strict; use v5.14;

GetOptions(
  'url=s'     => \(my $url),
  'file=s'    => \(my $file),
  'update'   => \(my $update),
  'verbose'   => \(my $verbose),
  'very_verbose' => \(my $very_verbose),
  'dry_run|n' => \(my $dry_run),
  'help|?'    => sub { pod2usage(verbose => 2) },
) or die pod2usage(verbose => 1);

pod2usage(msg => "missing url", verbose => 1) unless $url;
pod2usage(msg => "missing file", verbose => 1) unless $file;

my $n_updates = 0;

&main;

sub main {

    say "Update reference keys";
    say " url : $url";
    say " file : $file";
    say " update existing on" if $update;
    say " verbose on" if $verbose;
    say " very verbose on" if $very_verbose;
    say " dry run" if $dry_run;

    $verbose = 1 if $very_verbose;

    my $gcis = $dry_run ? Gcis::Client->new(url => $url) :
                       Gcis::Client->connect(url => $url);

    my $y = load_refs_data($file);
    foreach my $new_ref (@$y) {
        say "---";
        say " uri: $new_ref->{uri}";
        # Pull GCIS ref
        my $gcis_ref = $gcis->get($new_ref->{uri});
        if ( ! $gcis_ref ) {
            say " reference doesn't exist in GCIS, skipping: $new_ref->{uri}";
            next;
        }
        say " new ref :\n".Dumper($new_ref) if $very_verbose;
        say " gcis ref :\n".Dumper($gcis_ref->{attrs}) if $very_verbose;
        # Mesh info
        my $post_ref = mesh_reference($new_ref, $gcis_ref);
        update_ref($gcis_ref->{uri}, $gcis, $post_ref);
    }
    say "done";
}

sub load_refs_data {
    my $file = shift;

    open my $f, '<:encoding(UTF-8)', $file or die "can't open file : $file";

    my $yml = do { local $/; <$f> };
    my $y = Load($yml);

    return $y;
}

sub mesh_reference {
    my ($new_ref, $gcis_ref) = @_;
    my $post_ref->{identifier} = $gcis_ref->{identifier};
    my $attrs;

    delete $new_ref->{uri};
    # Initialize the attrs with the existing values
    foreach my $key ( keys %{$gcis_ref->{attrs}} ) {
        $attrs->{$key} = $gcis_ref->{attrs}->{$key};
    }

    # Process updating them
    foreach my $key ( keys %{$new_ref} ) {
        if ( $update ) {
            say " Setting $key to $new_ref->{$key}" if $verbose;
            # Update flag - update regardless of existing key
            $attrs->{$key} = $new_ref->{$key};
        }
        elsif ( defined $attrs->{$key} ) {
            say " No Update flag & key $key already exists - leaving as GCIS value $attrs->{$key} instead of new value $new_ref->{$key}" if $verbose;
            # No update - don't overwrite existing keys on ref
            next;
        }
        else {
            # No update - add new keys
            say " New key $key set to $new_ref->{$key}" if $verbose;
            $attrs->{$key} = $new_ref->{$key};
        }
    }

    $post_ref->{attrs} = $attrs;
    return $post_ref;
}

sub update_ref {
    my ($uri, $gcis, $post_ref) = @_;

    say " ref to post :\n".Dumper($post_ref) if $very_verbose;

    if ($dry_run) {
        say " would update reference for : $post_ref->{identifier}";
        return 0;
    }

    say " updating reference for : $uri";
    $gcis->post($uri, $post_ref) or 
        die " unable to add reference for : $post_ref->{identifier}";

    $n_updates++;

    return 1;
}
