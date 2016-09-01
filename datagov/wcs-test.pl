#!/usr/bin/env perl

use v5.20.1;
use Mojo::UserAgent;
use Data::Dumper;

sub see {
  my ($n, $b) = @_;
  my $s;
  $s .= "  " for 1..$n;
  say "$s [$n] ".$b->tag." (".$b->type.")";
  my $a = $b->attr;
#   say " a :\n".Dumper($a);
  my $i = 0;
  for (keys %$a) {
    say "$s     ".($i eq 0 ? "attr" : "    ")." [$i] : $_ => ".$a->{$_};
    $i++;
  }
  say "$s     text : ".$b->text if $b->text;
}

sub children {
  my ($p, $n) = @_;

  $n++;
  my $c = $p->children->first;
  while ($c) {
    see($n, $c);
    children($c, $n);
    $c = $c->next;
  }
}

my $url = 'http://catalog.data.gov/csw-all';

my $ua = Mojo::UserAgent->new;
$ua->max_redirects(3);

my $r = 'GetRecords';
my $a = '
  xmlns:csw="http://www.opengis.net/cat/csw/2.0.2"
  xmlns:ogc="http://www.opengis.net/ogc"
  service="CSW"
  version="2.0.2"
  resultType="results"
  startPosition="1"
  maxRecords="5"
  outputFormat="application/xml" 
  outputSchema="http://www.isotc211.org/2005/gmd"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation=
     "http://www.opengis.net/cat/csw/2.0.2
      http://schemas.opengis.net/csw/2.0.2/CSW-discovery.xsd">';
# outputSchema="http://www.isotc211.org/2005/gmd"
# outputSchema="http://www.opengis.net/cat/csw/2.0.2"

my $q1 = '
  <csw:Query typeNames="csw:Record">
    <csw:ElementSetName>brief</csw:ElementSetName>
    <csw:Constraint version="1.1.0">
      <ogc:Filter>
          <ogc:PropertyIsEqualTo>
            <ogc:PropertyName>csw:AnyText</ogc:PropertyName>
            <ogc:Literal>roads</ogc:Literal>
          </ogc:PropertyIsEqualTo>
      </ogc:Filter>
    </csw:Constraint>
  </csw:Query>';
my $p = 
"<csw:$r $a $q1
</csw:$r>";
say " p :\n$p";

my $u = $ua->post($url => $p) or die 'post failed';
my $t = $u->res->dom;


# say Dumper($t);

see(0, $t);
children($t, 0);
