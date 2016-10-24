#!/usr/bin/env perl

=head1 NAME

[FILENAME] -- [ONE LINE DESCRIPTION]

=head1 DESCRIPTION

[FULL EXPLANATION OF THE SCRIPT. Remember to explain the
'Why' and 'How' as well as the 'What'. Make note of any
externalities, such as GCIS (very common), CrossRef.org,
IO files, etc ]


=head1 SYNOPSIS

[GENERIC SCRIPT RUN e.g.: "./FILENAME [OPTIONS] < FOO.TXT"]

=head1 OPTIONS

=over

=item <stdin>

[STDIN DESCRIPTION (if used)]

=item B<--[FOO]>

[FOO DESCRIPTION]

=item B<--BAR>

[BAR DESCRIPTION]

=item B<--verbose>

Verbose option [IF USED; HIGHLY ENCOURAGED]

=item B<--dry_run>

Dry run [IF USED; HIGHLY ENCOURAGED]

=back

=head1 EXAMPLES

[REALISTIC SCRIPT RUN e.g. `./FILENAME --foo --verbose <input.txt`]

=cut

use utf8;
use v5.20;

use Gcis::Client;

my $c = Gcis::Client->connect(url => shift || 'http://localhost:3000');
my $lexicon = 'nsidc';

while (<DATA>) {
    chomp;
    my ($term,$gcid) = split /\s*:\s*/;
    say qq['$term' '$gcid' ];
    $c->post("/lexicon/$lexicon/term/new", {
            term => $term,
            gcid => $gcid,
            context => 'Sensor',
        }) or die $c->error;
}

__DATA__
AMSR-E : /instrument/advanced-microwave-scanning-radiometer-eos
AMSR : /instrument/advanced-microwave-scanning-radiometer
AMSU-A : /instrument/advanced-microwave-sounding-unit-a-2
ASAR : /instrument/advanced-synthetic-aperture-radar
ASTER : /instrument/advanced-spaceborne-thermal-emission-and-reflection-radiometer
ETM+ : /instrument/enhanced-thematic-mapper-plus
GLAS : /instrument/geoscience-laser-altimeter-system
HRVIR : /instrument/high-resolution-visible-and-infra-red
MISR : /instrument/multi-angle-imaging-spectroradiometer
MODIS : /instrument/moderate-resolution-imaging-spectroradiometer
NSCAT : /instrument/nasa-scatterometer
PALSAR : /instrument/phased-array-type-l-band-synthetic-aperture-radar
RA : /instrument/radar-altimeter-3
SSM/I : /instrument/special-sensor-microwave-imager
SSMIS : /instrument/special-sensor-microwave-imager-sounder
TM : /instrument/thematic-mapper
VAS : /instrument/vissr-atmospheric-sounder
