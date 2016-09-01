package Ckan;

use v5.18.2;
use Mojo::UserAgent;
use Mojo::JSON qw(decode_json);
use Data::Dumper;
use Scalar::Util qw(looks_like_number);
use DateTime::Format::ISO8601;

# my $ex = 'C1343-NSIDCV0';

sub new {
    my $class = shift;
    my $url = shift;

    my $s;
    my $s->{ua} = Mojo::UserAgent->new;
    $s->{ua}->max_redirects(3);
    $s->{url} = $url;
    $s->{n_max} = -1;

    bless $s, $class;
    return $s;
};

sub get_group {
    my $s = shift;
    my $group = shift;


    my $g = $s->{url}.'package_search?q=groups:'.$group;

    my @d;

    my $n = 0;
    while () {
        my $u = $g.'&start='.$n;
        # say " u : $u";
        my $c = $s->{ua}->get($u)->res or die 'ckan get failed';
        my $t = $c->json or die 'no json';
        my $r = $t->{result}->{results};
        scalar @{ $r } or last;
        for (@$r) {
            my $v = \%{ $d[$n] };
            # say " r :\n".Dumper($_);
            # say " id : $_->{id}";
            $n++;
            $v->{idDataGov} = $_->{id};
            $v->{idAgency} = _get_id_agency($_);
            # say " r :\n".Dumper($_) if $v->{idAgency} eq $ex;
            for my $i (qw(title name notes)) {
                next unless $_->{$i};
                $v->{$i} = $_->{$i};
            }
            if ($_->{organization}->{title}) {
                $v->{organization} = $_->{organization}->{title};
            }
            my $e = $_->{extras};
            for (@$e) {
                my $k = $_->{key};
                if (grep $k eq $_, qw(programCode bureauCode)) {
                    $v->{$k} = $_->{value}[0];
                    next;
                }
                if (grep $k eq $_, qw(describedBy landingPage)) {
                    $v->{$k} = $_->{value};
                    next;
                }
                if ($k eq 'spatial') {
                    my $s = _get_spatial($_->{value}) or next;
                    $v->{$k} = $s;
                    next;
                }
                if ($k eq 'temporal') {
                    my $t = _get_temporal($_->{value}) or next;
                    $v->{$k} = $t;
                    next;
                }
                if ($k eq 'responsible-party') {
                    my $p = _get_resp($_->{value}) or next;
                    $v->{$k} = $p;
                    next;
                }
                if ($k eq 'publisher') {
                    $v->{$k} = $_->{value};
                    next;
                }
                if ($k eq 'publisher_hierarchy') {
                    $v->{$k} = $_->{value};
                    $v->{$k} =~ s/ *> */, /g;
                    next;
                }
                if ($k eq '__category_tag_aa0c01c9-d292-4dc1-8fec-b10c1bb629a9') {
                    my $p = _get_tags($_->{value}) or next;
                    $v->{tags} = $p;
                    next;
                }
            }
            if (!$v->{spatial}) {
                my $bb = 0;
                for (@$e) {
                    next unless $_->{key} =~ /^bbox/;
                    $bb = 1;
                    last;
                }
                say " error - bounding box without spatial" if $bb;
            }
            for (@{ $_->{resources} }) {
                next unless $_->{resource_locator_function} = 'download';
                $v->{downloadURL} = $_->{url};
                last;
            }
            last if $s->{n_max} > 0  &&  $n >= $s->{n_max};
        }
        last if $s->{n_max} > 0  &&  $n >= $s->{n_max};
    }

    return \@d;
}

sub _get_id_agency {
    my $d = shift;
    for my $v (@{ $d->{extras} }) {
        for (qw(guid identifier)) {
            next unless $v->{key} eq $_;
            return $v->{value} if $v->{value};
        }
    }
    return $d->{id};
}

sub _get_spatial {
    my $s = shift;

    my %m;
    my $b1 = qq({"type": *"Polygon", *"coordinates": *);
    my $e1 = quotemeta qq(});
    my $poly = 0;
    my $p;
    if ($s =~ /^$b1/  &&  $s =~ /$e1$/ ) {
        ($p) = ($s =~ /^$b1(.*?)$e1$/);
        $p =~ s/^\[\[\[//;
        $p =~ s/\]\]\]$//;
        $p =~ s/\], *\[/ /g;
        $p =~ s/, */ /g;

        my @c = split / /, $p;
        my $n = grep looks_like_number($_), @c;
        if ($n != 10  ||  scalar @c != 10) {
            say " error : not a four sided polygon";
            say "         value : $s";
            return undef;
        }
        my $i = 0;
        my $j = 0;
        my @lon;
        my @lat;
        while ($i < 10) {
            $lon[$j] = $c[$i++];
            $lat[$j] = $c[$i++];
            $j++;
        }
        if ($lon[0] != $lon[4]) {
            say " error : first and last longitude don't match in polygon";
            say "         value : $s";
            return undef;
        }
        if ($lat[0] != $lat[4]) {
            say " error : first and last latitude don't match in polygon";
            say "         value : $s";
            return undef;
        }

        ($m{lon_min}, $m{lon_max}) = _min_max(@lon);
        ($m{lat_min}, $m{lat_max}) = _min_max(@lat);
        if ($lon[0] > $lon[1]) {
           my $t = $m{lon_min};
           $m{lon_min} = $m{lon_max};
           $m{lon_min} = $t;
        }
        return _valid_lat_lon(%m) ? \%m : undef;
    }

    my @p = split /, */, $s;
    if (@p != 4) {
        @p = split / +/, $s;
    }
    my $n = grep looks_like_number($_), @p;
    if ($n == 4  &&  scalar @p == 4) {
        ($m{lon_min}, $m{lat_min}, $m{lon_max}, $m{lat_max}) = @p;
        return _valid_lat_lon(%m) ? \%m : undef;
    }

    say " error - spatial not a polygon or bounding box";
    say "         value : $s";
    return undef;
}

sub _min_max {
    my @s = @_;
    my $first = 1;
    my ($a, $b);
    for (@s) {
        if ($first) {
            $a = $_;
            $b = $_;
            $first = 0;
            next;
        }
        $a = $_ if $_ < $a;
        $b = $_ if $_ > $b;
    }
    return ($a, $b);
}

sub _valid_lat_lon {
    my %m = @_;

    if ($m{lat_min} > $m{lat_max}  ||
        $m{lat_min} < -90.0  ||  $m{lat_min} > 90.0  ||
        $m{lat_max} < -90.0  ||  $m{lat_max} > 90.0) {
        say " error : minimum and/or maximum latitude invalid";
        say "         lat_min : $m{lat_min}  lat_max : $m{lat_max}";
        return 0;
    }
    if ($m{lon_min} < -180.0  ||  $m{lon_min} > 180.0  ||
        $m{lon_max} < -180.0  ||  $m{lon_max} > 180.0) {
        say " error : minimum and/or maximum longitude invalid";
        say "         lon_min : $m{lon_min}  lon_max : $m{lon_max}";
        return 0;
    }

    return 1;
}

sub _get_temporal {
    my $s = shift;

    my (@c) = split '/', $s;
    my %t;

    my $n = @c;
    if ($c[0] eq "R") {
        if ($n != 3  ||  $c[2] !~ /^P\d*[YMD]/) {
            say " error : invalid repeating temporal extent";
            say "         value : $s";
            return undef;
        }
        if (!eval { DateTime::Format::ISO8601->parse_datetime($c[1]) }) {
            say " error : invalid date time";
            say "         value : $s";
            return undef;
        }
        $t{start_time} = $c[1];
        return \%t;
    }
    if ($n != 2) {
        say " error : invalid temporal extent";
        say "         value : $s";
        return undef;
    }
    for (@c) {
        next if eval { DateTime::Format::ISO8601->parse_datetime($_) };
        say " error : invalid date time";
        say "         value : $s";
        return undef;
    }
    $t{start_time} = $c[0];
    $t{end_time} = $c[1];
    return \%t;
}

sub _get_resp {
    my $s = shift;

    # ex: [{"name": "U.S. Geological Survey", "roles": ["pointOfContact"]}]

    return undef unless $s =~ /^\[\{"/;

    my $d = decode_json($s);
    my $p;

    return undef unless grep $_->{name}, @$d;
    for (@$d) {
        $_->{name} or next;
        my $c = grep $_ eq 'pointOfContact', @{ $_->{roles} };
        $c or next;
        $p .= ' | ' if $p;
        $p .= $_->{name};
    }
    return $p if $p;

    for (@$d) {
        $_->{name} or next;
        my $c = grep $_ eq 'owner', @{ $_->{roles} };
        $c or next;
        $p .= ' | ' if $p;
        $p .= $_->{name};
    }
    return $p if $p;
}

sub _get_tags {
    my $s = shift;
    
    # ex: ["Energy Infrastructure","Human Health"]

    return undef unless $s =~ /^\["/;

    my $d = decode_json($s);
    # say " d :\n".Dumper($d);
    return $d;
}

1;    
