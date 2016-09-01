#!/usr/bin/env perl

use v5.18.1;
use Data::Dumper;
use YAML::XS qw/Load Dump/;

my $n_max = -1;

main();

exit;

sub main {
    my $n = 0;
    my @d;

    my $r = load_list();
    my $o = load_list('other_ids.yaml');
    my $e;
    $e->{$_->{term}} = $_->{gcid} for @$o;

    for (@$r) {
        $n++;
        last if $n_max > 0  &&  $n > $n_max;

        my $w;
        my $t = $_->{name};
        $w->{dataset} = $t;
        $w->{identifier} = $_->{idDataGov};
        if ($e->{$t}) {
            $w->{gcid} = $e->{$t};
            push @d, $w;
            next;
        }

        $w->{gcid} = make_gcid($_) or do {
            say " name : $t";
            say "   idAgency : $_->{idAgency}";
            say "   downloadURL : $_->{downloadURL}";
            next;
        };
        push @d, $w;
    }

    say Dump(\@d);

    return;
}

sub load_list {
    my $file = shift;

    my $yml;
    if ($file) {
        open my $f, '<', $file or die "can't open file : $file";
        $yml = do { local $/; <$f> };
        close $f;
    } else {
        $yml = do { local $/; <> };
    }
    my $e = Load($yml);

    return $e;
}

sub make_gcid {
    my $r = shift;

    my $a = $r->{idAgency};
    my $d = $r->{downloadURL};
    $d =~ s/^(ht|f)tps*\:\/\///i;
    my $b = $r->{describedBy};
    $b =~ s/^https*\:\/\///i;

    # NOAA

    if ($a =~ /^gov\.noaa\./i) {
        $a =~ s/^gov\.noaa\.//i;
        if ($a =~ /^([\w\.]+):([\w\-]+)$/i) {
            my $c = lc $1;
            my $n = lc $2;
            $c =~ s/[\._]/\-/g;
            $n =~ s/[\._]/\-/g;
            if ($c =~ /^cpc$/) {
                $n =~ s/^cpc\-//;
            }
            if ($c =~ /^ngdc$/) {
                $n =~ s/^ngdc\-//;
            }
            return "/dataset/noaa-$c-$n";
        }
        return undef;
    }

    if ($a =~ /^noaa\-(\w+)\-(\d+)$/i) {
        my $c = lc $1;
        my $n = $2;
        return undef unless $d =~ /noaa\.gov\/pls\/paleox\//i;
        return "/dataset/noaa-paleo-$c-$n";
    }

    if ($d =~ /\.noaa\.gov(\/|$)/i) {

        if ($d =~ /^ftp\.(coast|csc)\.noaa\.gov\/pub\/msp\/(\w+)\.zip$/i) {
            my $c = lc $1;
            my $n = decamelize($2);
            $n =~ s/\_/-/g;
            return "/dataset/noaa-$c-msp-$n";
        }

        if ($d =~ /^egisws\d+\.nos\.noaa\.gov\/arcgis\/rest\/services\/esi\/(\w+)\/mapserver$/i) {
            my $n = lc $1;
            $n =~ s/\_/-/g;
            return "/dataset/noaa-nos-$n";
        }

        if ($d =~ /^(response\.restoration|coast|tidesandcurrents)\.noaa\.gov\//i) {
            my $n = lc $r->{name};
            $n =~ s/^noaas*-//;
            return "/dataset/noaa-$n";
        }

        if ($d =~ /^(marineprotectedareas|nowcoast|shoreline|weather)\.noaa\.gov\//i) {
            my $n = lc $r->{name};
            $n =~ s/^noaas*-//;
            return "/dataset/noaa-$n";
        }

        if ($d =~ /^(weather|estuarinebathymetry)\.noaa\.gov/i) {
            my $n = lc $r->{name};
            return "/dataset/noaa-$n";
        }

        if ($d =~ /^(coastwatch|storms)\.\w+\.noaa\.gov\//i) {
            my $n = lc $r->{name};
            $n =~ s/^noaas*-//;
            return "/dataset/noaa-$n";
        }

        if ($d =~ /^www\.(habitat|ngdc|nmfs|nws|srh)\.noaa\.gov\//i) {
            my $n = lc $r->{name};
            $n =~ s/^noaas*-//;
            $n =~ s/^national-weather-service/nws/;
            return "/dataset/noaa-$n";
        }

        if ($d =~ /^www\.(tidesandcurrents|nauticalcharts)\.noaa\.gov\//i) {
            my $n = lc $r->{name};
            return "/dataset/noaa-$n";
        }

        if ($d =~ /^www1\.ncdc\.noaa\.gov\//i) {
            my $n = lc $r->{name};
            return "/dataset/noaa-$n";
        }

        if ($d =~ /^data1\.gfdl\.noaa\.gov$/i) {
            my $n = lc $r->{name};
            return "/dataset/noaa-$n";
        }

       return undef;
    }

    if ($d =~ /\.(aviation|)weather\.gov/i) {
        my $n = lc $r->{name};
        $n =~ s/national-weather-service-//;
        return "/dataset/noaa-nws-$n";
    }

    # Census

    if ($d =~ /^[\w\.]+\.census\.gov\//i) {
        my $n = lc $r->{name};
        return "/dataset/census-$n";
    }

    # USDA

    if ($a =~ /^usda\-([\w\-]+)$/i) {
        my $n = lc $1;
        if ($d =~ /(ers|fas|fsa|nrcs)\.usda\.gov\//i) {
            $n = "$1-".$n if $n !~ /^$1-/i;;
        }
        return "/dataset/usda-$n";
    }

    if ($d =~ /\.usda\.gov/i) {
        my $n = lc $r->{name};
        $n =~ s/^us-forest-service-/fs-/;
        $n =~ s/-direct-download$//;
        return "/dataset/usda-$n";
    }

    if ($d =~ /fs\.fed\.us\//i) {
        if ($d =~ /^apps\.fs\.fed\.us\//i) {
            my $n = lc $r->{name};
            return "/dataset/usda-fs-$n";
        }
        return undef;
    }

    if ($d =~ /\.landfire\.gov/i) {
        if ($d =~ /^www\.landfire\.gov\/NationalProductDescriptions\d+\.php/i) {
            my $n = lc $r->{name};
            $n =~ s/^us-forest-service-/fs-/;
            return "/dataset/usda-$n";
        }
        return undef;
    }

    if ($a =~ /^nrcs(\d+)$/i) {
        my $n = $1;
        return "/dataset/usda-nrcs-$n";
    }

    # DOD and DOI

    if ($a =~ /^(dod|doi)-([\d\-]+)$/i) {
        my $a = lc $1;
        my $n = lc $2;
        return "/dataset/$a-$n";
    }

    # DOE

    if ($a =~ /^doe\-([\d\-]+)$/i) {
        my $n = $1;
        return "/dataset/doe-$n";
    }

    if ($d =~ /openei\.org\/doe\-opendata/i) {
        $d =~ s/^en\.openei\.org\/doe\-opendata\/dataset\///i;
        if ($d =~ /^([\w+\-]+)\//i) {
            my $n = $r->{name};
            return "/dataset/doe-$n";
        }
        return undef;
    }

    if ($a =~ /openei\.org\/doe\-opendata/i) {
        $a =~ s/^https*\:\/\///i;
        $a =~ s/^en\.openei\.org\/doe\-opendata\/dataset\///i;
        if ($a =~ /^([\w+\-]+)$/i) {
            my $n = lc $r->{name};
            return "/dataset/doe-$n";
        }
        return undef;
    }

    # DOT

    if ($d =~ /^www\.bts\.gov\//i) {
        if ($d =~ /^www\.bts\.gov\/programs\/geographic_information_services\//i) {
           my $n = lc $r->{name};
           return "/dataset/dot-$n";
        }
        return undef;
    }

    if ($d =~ /dot\.gov\//i) {
        if ($d =~ /^www\.rita\.dot\.gov\/bts\/sites\//i) {
           my $n = lc $r->{name};
           return "/dataset/dot-$n";
        }
        return undef;
    }

    # FWS

    if ($a =~ /^fws_servcat_(\d+)$/i) {
        my $n = $1;
        return "/dataset/fws-servcat-$n";
    }

    if ($d =~ /arcticlcc\.org/i) {
        $d =~ s/arcticlcc\.org\/[\w\/]+\///i;
        if ($d =~ /^(arct|alcc)\d+-\d+\/*/i) {
            my $n = lc $r->{name};
            return "/dataset/fws-arcticlcc-$n";
        }
        if ($d =~ /data\.arcticlcc\.org\/\d+-\d+\//i) {
            my $n = lc $r->{name};
            return "/dataset/fws-arcticlcc-$n";
        }
        return undef;
    }

    # HUD

    if ($a =~ /^hud(\d+)$/i) {
        my $n = $1;
        return "/dataset/hud-$n";
    }

    # EPA

    if ($d =~ /\.epa\.gov\//i) {
        if ($d =~ /^edg\.epa\.gov\/data\/public\/ord\/enviroatlas\/national$/i) {
           my $n = lc $r->{name};
           return "/dataset/epa-$n";
        }
        if ($d =~ /(www|ww2|iaspub|edg|water|watersgeo)\.epa\.gov/i) {
           my $n = lc $r->{name};
           return "/dataset/epa-$n";
        }
        return undef;
    }

    # NASA

    if ($a =~ /^noaa\.ncei\.nsidc\.(\w+)$/i) {
        my $n = lc $1;
        return "/dataset/nsidc-$n";
    }

    if ($d =~ /nsidc\.org/i) {
        $d =~ s/^nsidc\.org\/data//i;
        if ($d =~ /^\/nsidc-(\d+)\.html$/i) {
           my $n = $1;
           return "/dataset/nasa-nsidcdaac-$n";
        } elsif ($d =~ /^\/(\w+)\.html$/i) { 
           my $n = lc $1;
           return "/dataset/nasa-nsidcdaac-$n";
        } elsif ($d =~ /^-set\/(\w+)\/order-form$/i) {
           my $n = lc $1;
           return "/dataset/nsidc-$n";
        }
        return undef;
    }

    if ($d =~ /nasa\.gov/i) {
        $d =~ s/^hydro1\.sci\.gsfc\.nasa\.gov\/data\/s4pa\/[ng]ldas\///i;
        if ($d =~ /^(\w+\.\d+)\/$/i) {
            my $n = lc $1;
            $n =~ s/[\_\.]/-/g;
            return "/dataset/nasa-gesdisc-$n";
        }
        return undef;
    }

    if ($d =~ /columbia\.edu/i) {
        $d =~ s/sedac\.ciesin\.columbia\.edu\/data\/set\///i;
        if ($d =~ /^([\w\-]+)\/data-download$/) {
           my $n = lc $1;
           return "/dataset/nasa-sedac-$n";
        }
        return undef;
    }

    if ($d =~ /ornl\.gov/i) {
        $d =~ s/^daac\.ornl\.gov\/cgi-bin\/dsviewer\.pl\?ds_id=//i;
        if ($d =~ /^(\d+)$/) {
           my $n = $1;
           return "/dataset/nasa-ornldaac-$n";
        }
        if ($d =~ /^\w+\.usgs\.ornl\.gov\/#api$/i) {
           my $n = lc $r->{name};
           return "/dataset/usgs-$n";
        }
        return undef;
    }

    # USGS

    if ($d =~ /^dx.doi.org\/10\.5066\/\w+/i) {
        my $n = lc $r->{name};
        return "/dataset/usgs-$n";
    }

    if ($d =~ /^landcarbon\.org\//i) {
        if ($d =~ /^landcarbon\.org\/categories\/([\w\-]+)\/download\/$/i) {
            my $n = lc $1;
            return "/dataset/usgs-landcarbon-$n";
        }
        return undef;
    }

    if ($d =~ /oregonstate\.edu\:/i) {
        if ($d =~ /^regclim\.coas\.oregonstate\.edu\:8080\/thredds\//i) {
            my $n = lc $r->{name};
            $n =~ s/^usgs-//;
            return "/dataset/usgs-regclim-$n";
        }
        return undef;
    }

    if ($d =~ /^\w+\.nationalmap\.gov\//i) {
        if ($d =~ /^\w+\.nationalmap\.gov\/arcgis\/rest\/services\/([\w\/]+)\/mapserver$/i) {
            my $n = lc $r->{name};
            $n =~ s/^usgs-//;
            return "/dataset/usgs-$n";
        }
        return undef;
    }

    if ($d =~ /usgs\.gov/i) {

        if ($d =~ /(\w+)\.usgs\.gov\//i) {
           my $n = lc $r->{name};
           $n =~ s/^usgs\-//;
           $n =~ s/^u\-s\-geological\-survey\-//g;
           $n =~ s/-direct-download$//;
           if ($n =~ /([\w\-]+)-downloadable-data-collection-/) {
               $n = $1;
           }
           return "/dataset/usgs-$n";
        }
        return undef;
    }

    # CDC

    if ($d =~ /cdc\.gov\//i) {
        if ($d =~ /^wonder\.cdc\.gov\/([\w\-]+)\.html$/i) {
            my $n = lc $r->{name};
            return "/dataset/$n";
        }
        if ($d =~ /^www\.cdc\.gov\/nchs\/([\w\-]+)\.htm$/i) {
            my $n = lc $r->{name};
            return "/dataset/cdc-$n";
        }
        if ($d =~ /^www(2c|)\.cdc\.gov\/(.*)/i) {
            my $n = lc $r->{name};
            $n =~ s/^cdc-//;
            return "/dataset/cdc-$n";
        }

        return undef;
    }

    if ($b =~ /cdc\.gov\//i) {
        if ($b =~ /^www\.cdc\.gov\/nchs\/[\w\-\/]+\.htm$/i) {
            my $n = lc $r->{name};
            return "/dataset/cdc-$n";
        }
        return undef;
    }

    return undef
}

# from https://gist.github.com/tyru/358703

sub decamelize {
    my ($s) = @_;
    $s =~ s{(\w+)}{
        ($a = $1) =~ s<(^[A-Z]|(?![a-z])[A-Z])><
            "_" . lc $1
        >eg;
        substr $a, 1;
    }eg;
    $s;
}
