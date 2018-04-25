#!/usr/bin/env perl

=head1 NAME

update_gcmd_keywords.pl -- updates GCMD Keywords & their structure

=head1 DESCRIPTION

This script, when run, will update the GCMD keywords to the latest versions available
from GCMD's XML endpoint. See README.md

=head1 SYNOPSIS

./update_gcmd_keywords.pl [OPTIONS]

=head1 OPTIONS

=over

=item B<--url>

The GCIS instance URL

=item B<--root_keyword>

The UUID of the root node GCMD keyword. Default '1eb0ea0a-312c-4d74-8d42-6f1ad758f999', "Science Keywords"

=item B<--data_only>

Updates the Labels and Definition, but no reorganizing

=item B<--dryrun>

If set, no changes are made but instead a list of updates, moves, creations, & defunct are output.

=item B<--verbose>

Verbose output

=back

=head1 EXAMPLES

./update_gcmd_keywords.pl --url "https://data.globalchange.gov" --doi doi-file.txt --csv output.csv

=cut

use Gcis::Client;
use Data::Dumper;
use Getopt::Long qw/GetOptions/;
use Text::CSV;
use Mojolicious;
use XML::LibXML;
use XML::Hash::LX;
use LWP::UserAgent;
use Utils;

use v5.16;

GetOptions(
  'url=s'           => \(my $url),
  'root_keyword=s'  => \(my $root_keyword = '1eb0ea0a-312c-4d74-8d42-6f1ad758f999'),
  'data_only!'      => \(my $data_only),
  'dryrun!'         => \(my $dry),
  'limit=s'         => \(my $limit),
  'verbose!'        => \(my $verbose),
) or die "bad opts";

die 'missing url' unless $url;

my $gcis = Gcis::Client->connect(url => $url);
my $gcmd = LWP::UserAgent->new();
$gcmd->ssl_opts(verify_hostname => 0);
$gcmd->default_header('Content-Type' => 'application/xml');


my $checked_uuids;

my $differing_keywords;
my $moved_keywords;
my $new_keywords;
my $new_keywords_ordered; #makes sure parents are created before kids
my $defunct_keywords;
my $unchanged = 0;
my $invalid = 0;
my $differs = 0;
my $gcis_uptodate = 1;

my $count = 0;
my $gcmd_version;

{

    keyword_analyze( gcmd_uuid => $root_keyword );

    my $differing = keys %$differing_keywords // 0;
    my $new = keys %$new_keywords // 0;
    my $defunct = keys %$defunct_keywords // 0;
    my $moved = keys %$moved_keywords // 0;
    say "Found $new new keywords, $defunct defunct keywords, $differs differing keywords ($differing with differences, $moved moved).";
    say "$unchanged in good standing, $invalid invalid keywords.";

    process_updates( differing => $differing, new => $new, defunct => $defunct, moved => $moved );

    my $result;
    $result .= "DRY-RUN: " if $dry;
    if ( $gcis_uptodate ) {
        $result .= "GCIS already matches $gcmd_version";
    }
    else {
        $result .= "Updated GCIS to GCMD Keywords Version $gcmd_version";
        $result .= $data_only ? " data fields (label/definition) only." : " data fields & parent structure.";
    }
    say $result;
}


=head2 Query Functions

=cut

sub keyword_analyze {
    my (%params) = @_;
    my $keyword = $params{gcmd_uuid};

    if ( $limit ) {
        return 1 if $count >= $limit;
    }

    # Don't reprocess seen UUIDS
    return 1 if $checked_uuids->{$keyword};

    print "Checking keyword $keyword - " if $verbose;
    #Snag the GCIS Keyword
    my $gcis_keyword_info = $gcis->get("/gcmd_keyword/$keyword.json");
    my $gcis_keyword      = clean_gcis($gcis_keyword_info);

    #Snag the GCMD keyword
    my $gcmd_keyword_info = get_gcmd_keyword($keyword);
    my $gcmd_keyword      = clean_gcmd($gcmd_keyword_info);

    #say Dumper $gcmd_keyword;
    #say Dumper $gcis_keyword;

    my @all_children;
    if ( ! defined $gcis_keyword  && ! defined $gcmd_keyword ) {
        # throw an error? 
        say "No such keyword exists in either system" if $verbose;
        $invalid++;
        $gcis_uptodate = 0;
    }
    elsif ( ! defined $gcis_keyword ) {
        say " ($gcmd_keyword->{label}) new to GCIS" if $verbose;
        $new_keywords->{$keyword} = $gcmd_keyword;
        push @$new_keywords_ordered, $keyword;
        @all_children = @{ $gcmd_keyword->{children}};
        $gcis_uptodate = 0;
    }
    elsif ( ! defined $gcmd_keyword ) {
        say " ($gcis_keyword->{label}) now defunct" if $verbose;
        $defunct_keywords->{$keyword} = $gcis_keyword;
        @all_children = @{ $gcis_keyword->{children}};
        $gcis_uptodate = 0;
    }
    elsif (my ($differences, $moved) = find_differences(gcis => $gcis_keyword, gcmd => $gcmd_keyword) ) {
        my $uptodate = 1;
        if ( $differences ) {
            print " ($gcis_keyword->{label}) label/definition differs!" if $verbose;
            $differing_keywords->{$keyword} = $differences;
            $uptodate = 0;
        }
        if ( $moved ) {
            print " ($gcis_keyword->{label}) moved!" if $verbose;
            $moved_keywords->{$keyword} = $moved;
            $uptodate = 0;
        }

        if ($uptodate) {
            say " ($gcmd_keyword->{label}) up to date" if $verbose;
            $unchanged++;
        }
        else {
            $gcis_uptodate = 0;
            $differs++;
            print "\n" if $verbose;
        }
        @all_children = ( @{$gcis_keyword->{children}}, @{$gcmd_keyword->{children}} );
    }
    else {
        say " ($gcmd_keyword->{label}) up to date" if $verbose;
        $unchanged++;
        @all_children = ( @{$gcis_keyword->{children}}, @{$gcmd_keyword->{children}} );
    }

    $checked_uuids->{$keyword} = 1;

    $count++;
    foreach my $child ( @all_children ) {
        keyword_analyze(gcmd_uuid => $child);
    }

    return;
}

sub find_differences {
    my ( %params ) = @_;
    my $gcis_keyword = $params{gcis};
    my $gcmd_keyword = $params{gcmd};
    my $field = $params{fields};

    my $differences;
    my $fields = ['definition', 'label'];
    for my $field ( @$fields ) {
        if ( $gcis_keyword->{$field} ne $gcmd_keyword->{$field} ) {
            $differences->{gcis} = $gcis_keyword;
            $differences->{gcmd} = $gcmd_keyword;
            last;
        }
    }

    my $moved;
    if ( $gcis_keyword->{'parent_identifier'} ne $gcmd_keyword->{'parent_identifier'} ) {
        $moved->{gcis} = $gcis_keyword;
        $moved->{gcmd} = $gcmd_keyword;
    }
    return ($differences, $moved);
}

sub clean_gcis {
    my ( $heavy_gcis ) = @_;

    return unless $heavy_gcis;

    #say "Collecting children for $heavy_gcis->{identifier}" if $verbose;
    my $children = [];
    my $gcis_children = $gcis->get("/gcmd_keyword/$heavy_gcis->{identifier}/children.json");
    if ( $gcis_children ) {
        foreach my $kid ( @$gcis_children  ) {
            push @$children, $kid->{identifier};
        }
    }

    my $clean_gcis = {
        identifier        => $heavy_gcis->{identifier},
        definition        => $heavy_gcis->{definition},
        label             => $heavy_gcis->{label},
        parent_identifier => $heavy_gcis->{parent_identifier},
        children          => $children,
    };

    return $clean_gcis;
}

sub get_gcmd_keyword {
    my ($keyword) = @_;

    my $baseURL           = q{https://gcmd.nasa.gov/kms/concept/};
    my $endURL            = q{?format=xml};
    my $gcmd_url          = $baseURL . $keyword . $endURL;
    my $gcmd_keyword_xml  = $gcmd->get( $gcmd_url );
    return unless $gcmd_keyword_xml->is_success;

    my $parser            = XML::LibXML->new();
    return xml2hash $gcmd_keyword_xml->content;
}

sub clean_gcmd {
    my ( $heavy_gcmd ) = @_;

    return unless $heavy_gcmd;

    $gcmd_version = $heavy_gcmd->{concept}{keywordVersion} unless $gcmd_version;

    my $children = [];
    if ( $heavy_gcmd->{concept}{narrower} ) {
        if ( ref $heavy_gcmd->{concept}{narrower}{conceptBrief} eq 'ARRAY' ) {
            foreach my $kid ( @{ $heavy_gcmd->{concept}{narrower}{conceptBrief} } ) {
                push @$children, $kid->{'-uuid'};
            }
        }
        else {
                push @$children, $heavy_gcmd->{concept}{narrower}{conceptBrief}{'-uuid'};
        }
    }
    my $clean_gmcd = {
        identifier        => $heavy_gcmd->{concept}{'-uuid'},
        definition        => $heavy_gcmd->{concept}{definition} ? $heavy_gcmd->{concept}{definition}{'#text'}            : undef,
        label             => $heavy_gcmd->{concept}{prefLabel}  ? $heavy_gcmd->{concept}{prefLabel}{'#text'}             : undef,
        parent_identifier => $heavy_gcmd->{concept}{broader}    ? $heavy_gcmd->{concept}{broader}{conceptBrief}{'-uuid'} : undef,
        children          => $children,
    };

    return $clean_gmcd;
}

=head2 Update Functions

=cut

sub process_updates {
    my (%params) = @_;
    my $new       = $params{new};
    my $differing = $params{differing};
    my $moved     = $params{moved};
    my $defunct   = $params{defunct};

    # Add new keywords - must be first
    add_new_keywords() if $new;

    # update the data fields
    update_data_fields() if $differing;

    # announce defunct entities
    delete_keywords() if $defunct;

    if ( ! $data_only ) {
        move_keywords() if $moved;
        # reassign parents
    }
    else {
        say "data_only flag prevents movement of keywords" if $verbose;
    }

    return;
}

sub update_data_fields {
    foreach my $keyword ( keys %$differing_keywords ) {
        my $gcmd_keyword = $differing_keywords->{$keyword}{gcmd};
        my $gcis_keyword = $differing_keywords->{$keyword}{gcis};
        if ( $dry ) {
            say "DRY: Would update data fields on $keyword ($gcis_keyword->{label})";
        }
        else {
            my $updates = {
                identifier        => $gcis_keyword->{identifier},
                label             => $gcmd_keyword->{label},
                parent_identifier => $gcis_keyword->{parent_identifier},
                definition        => $gcmd_keyword->{definition},
                audit_note        => "Updating data fields to GCMD $gcmd_version",
            };
            $gcis->post("/gcmd_keyword/$gcis_keyword->{identifier}", $updates);
            say "Updated data fields on $keyword ($gcis_keyword->{label})";
        }
    }
}

sub add_new_keywords {
    foreach my $keyword ( @$new_keywords_ordered ) {
        my $gcmd_keyword = $new_keywords->{$keyword};
        if ( $dry ) {
            say "DRY: Would add $keyword ($gcmd_keyword->{label})";
        }
        else {
            my $updates = {
                identifier        => $gcmd_keyword->{identifier},
                label             => $gcmd_keyword->{label},
                parent_identifier => $gcmd_keyword->{parent_identifier},
                definition        => $gcmd_keyword->{definition},
                audit_note        => "Adding keyword as part of update to GCMD $gcmd_version",
            };
            $gcis->post("/gcmd_keyword", $updates);
            say "Added $keyword ($gcmd_keyword->{label})";
        }
    }
}

sub move_keywords {
    foreach my $keyword ( keys %$moved_keywords ) {
        my $gcmd_keyword = $moved_keywords->{$keyword}{gcmd};
        my $gcis_keyword = $moved_keywords->{$keyword}{gcis};
        if ( $dry ) {
            say "DRY: Would move $keyword ($gcis_keyword->{label}) from $gcis_keyword->{parent_identifier} to $gcmd_keyword->{parent_identifier}";
        }
        else {
            my $updates = {
                identifier        => $gcis_keyword->{identifier},
                label             => $gcis_keyword->{label},
                parent_identifier => $gcmd_keyword->{parent_identifier},
                definition        => $gcis_keyword->{definition},
                audit_note        => "Changing parent keyword as part of update to GCMD $gcmd_version",
            };
            $gcis->post("/gcmd_keyword/$gcis_keyword->{identifier}", $updates);
            say "Moved $keyword ($gcis_keyword->{label}) from $gcis_keyword->{parent_identifier} to $gcmd_keyword->{parent_identifier}";
        }
    }
}

sub delete_keywords {
    foreach my $keyword ( keys %$defunct_keywords ) {
        my $gcis_keyword = $defunct_keywords->{$keyword}{gcis};
        print "DRY: " if $dry;
        say "DEFUNCT keyword $keyword ($gcis_keyword->{label}) should be removed by hand";
    }
}

