#!/usr/bin/env perl

use v5.18.1;
use Data::Dumper;
use YAML::XS qw/Load Dump/;
use Iso;

my $base_url = 'http://catalog.data.gov/';
my $wcs_url = $base_url.'csw-all/';
my $n_max = 50;

my $r = load_list();

my $n = 0;
my @d;
for (@$r) {
   $n++;
   # say " idAgency : $_->{idAgency}";
   my $w = get_wcs($wcs_url, $_);
   $w->{_ckan} = $_;
   push @d, $w;
   # say " w : \n".Dumper($w);
   last if $n_max > 0  &&  $n >= $n_max;
}

say Dump(\@d);

exit;

sub load_list {

    my $yml = do { local $/; <> };
    my $e = Load($yml);

    return $e;
}

sub get_wcs {
    my ($u, $d) = @_;

    my %v;

    my $ua = Mojo::UserAgent->new;
    $ua->max_redirects(3);

    my $p2_prefix =
        '<csw:GetRecords
           xmlns:csw="http://www.opengis.net/cat/csw/2.0.2"
           xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
           xsi:schemaLocation=
             "http://www.opengis.net/cat/csw/2.0.2
              http://schemas.opengis.net/csw/2.0.2/CSW-discovery.xsd"
           service="CSW"
           xmlns:ogc="http://www.opengis.net/ogc"
           version="2.0.2"
           resultType="results"
           startPosition="1"
           maxRecords="15"
           outputFormat="application/xml"
           outputSchema="http://www.isotc211.org/2005/gmd">
           <csw:Query typeNames="csw:Record">
             <csw:ElementSetName>brief</csw:ElementSetName>
             <csw:Constraint version="1.1.0">
               <ogc:Filter>';
    my $p2_suffix =
              '</ogc:Filter>
             </csw:Constraint>
           </csw:Query>
         </csw:GetRecords>';

    my $r;
    my $n = 0;

    my %prop = (idAgency => 'identifier', title => 'title');
    for (keys %prop) {
        next unless $d->{$_};
        my $f =
            '<ogc:PropertyIsEqualTo>
               <ogc:PropertyName>dc:'.$prop{$_}.'</ogc:PropertyName>
               <ogc:Literal>'.$d->{$_}.'</ogc:Literal>
             </ogc:PropertyIsEqualTo>';
        my $p = $p2_prefix.$f.$p2_suffix;

        my $u = $ua->post($u => $p) or die 'wcs post failed';
        my $m = $u->res->dom;
        # say " dom : \n".Dumper($u->res->dom);

        $r = $m->at('csw\:GetRecordsResponse > csw\:SearchResults');
        if (!defined $r) {
            if (!$m->at('body > h1')) {
                say ' error - unknown';
                next;
            }
            if ($m->at('body > h1')->text eq 'Forbidden') {
                say ' error - access forbidden';
                say '   '.$m->at('body > p')->text;
                next;
            }
            say " error - no response";
            next;
        }
        $n = $r->attr->{numberOfRecordsMatched};
        last if $n == 1;
    }
    if ($n != 1) {
        say " error - wrong number of matches ($n)";
        $v{error} = "wrong number of matches ($n)";
        return \%v;
    }

    my $r1 = $r->at('gmd\:MD_Metadata');
    $r1 or $r1 = $r->at('gmi\:MI_Metadata');

    my $s = Iso->set_dom($r1, $d->{idAgency});
    my $v1 = $s->get_meta;
    @v{keys %$v1} = values %$v1;

    for my $e (qw(spatial temporal)) {
        next unless $d->{$e};
        for (keys %{ $d->{$e} }) {
            next if $v{$_};
            $v{$_} = $d->{$e}->{$_};
        }
    }

    fix_poc(\%v);

    return \%v;
}

sub fix_poc {
    my $d = shift;

    # my $at = '@type';
    # my $t = qq({u'subOrganizationOf': {u'subOrganizationOf': {u'name': u'U.S. Government'}, u'name': u'National Aeronautics and Space Administration'}, u'name': u'NSIDC'});
    # my $t = qq({u'$at': u'org:Organization', u'name': u'Centers for Disease Control and Prevention'});
    # my $d->{_poc_org} = $t;

    my $v = $d->{_poc_org} or return;


    my $t = '@type';
    my $n = qq(u'name': *u');
    my $o = qq(u'$t': *u'org:Organization', *$n);

    if ($v =~ /^{$o.+'}$/ ) {
        ($d->{_poc_org}) = ($v =~ /^{$o(.+)'}$/);
        return;
    }

    my $so = qq(u'subOrganizationOf': *{);

    if ($v =~ /^{$so$o.+}, *$o.+'}$/) {
        my ($org, $sub_org) = ($v =~ /^{$so$o(.+)}, *$o(.+)'}$/);
        $d->{_poc_org} = "$sub_org, $org";
        return;
    }

    return unless $v =~ /^{$so$so$n.+'}, *$n.+'}, *$n.+'}$/;
    my ($org, $sub_org1, $sub_org2) = ($v =~ /^{$so$so$n(.+)'}, *$n(.+)'}, *$n(.+)'}$/);
    $d->{_poc_org} = "$sub_org2, $sub_org1, $org";

    return;
}

