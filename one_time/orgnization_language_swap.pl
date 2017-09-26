#!/usr/bin/env perl

=head1 NAME

./organization_language_swap.pl - change foreign ID orgs to english

=head1 DESCRIPTION

Given the DATA section of foreign language ID'd organizations,
change the identifier and name to english. and set an alternative id
with their original foreign language name.

=head1 SYNOPSIS

./organization_language_swap.pl GCIS_URL

=head1 OPTIONS

=over

=item GCIS_URL

The URL of the GCIS instance to modify.

=back

=head1 EXAMPLES

./organization_language_swap.pl https://data-stage.globalchange.gov

=cut

use utf8;
use v5.20;

use Gcis::Client;
use Data::Dumper;
use Try::Tiny;

my $url = shift || die "URL required";
my $c = Gcis::Client->connect(url => $url);

while (<DATA>) {
    chomp;
    # organization_identifier : Organization Name : Language code  : English Alias (Primary) : English identifier (Primary)
    my ($org_id_fr, $org_name_fr, $fr_lang, $org_name_en, $org_id_en) = split / : /;
    say " Foreign ID: $org_id_fr\n\tForeign Name: $org_name_fr\n\tForeign Lang: $fr_lang\n\tEnglish ID: $org_id_en\n\tEnglish Name: $org_name_en";

    my $existing = $c->get("/organization/$org_id_fr.json") or die "No organization $org_id_fr found";
    #say Dumper $existing;

    if ( $existing->{identifier} eq $org_id_en ) {
        print "\t\tAlready swapped ID\n";
        next;
    }
    $c->post("/organization/$org_id_fr.json", {
            identifier                   => $org_id_en,
            name                         => $org_name_en,
            organization_type_identifier => $existing->{organization_type_identifier},
            url                          => $existing->{url},
            international                => $existing->{international},
            country_code                 => $existing->{country},
        }) or die $c->error;
    say "\t\tUpdated Name and ID";
    $c->post("/organization_alternate_name", {
                organization_identifier => $org_id_en,
                alternate_name          => $org_name_fr,
                language                => $fr_lang,
        }) or die $c->error;
    say "\t\tAdded alternate name";
}

# organization_identifier : Organization Name : Language code  : English Alias (Primary) : English identifier (Primary)
__DATA__
istituto-agrario-di-san-michele-alladige-research-innovation-centre : Istituto Agrario di San Michele all'Adige Research and Innovation Centre : it : Agricultural Institute of San Michele all'Adige Research and Innovation Centre : agricultural-institute-san-michele-alladige-research-innovation-centre
clinique-psychiatrie-psychologie-medicale : Clinique de Psychiatrie et de Psychologie Médicale : fr : Clinic of Psychiatry and Medical Psychology : clinic-psychiatry-medical-psychology
universidad-federal-vicosa-department-agricultural-engineering : Universidad Federal de Viçosa Department of Agricultural Engineering : es : Federal University of Viçosa Department of Agricultural Engineering : federal-university-vicosa-department-agricultural-engineering
institut-louis-malarde-laboratoire-des-micro-algues-toxiques : Institut Louis-Malardé Laboratoire des Micro-Algues Toxiques : fr : Institute of Louis-Malardé Laboratory of Toxic Microalgae : institute-louis-malarde-laboratory-toxic-microalgae
institut-national-de-la-recherche-agronomique-unite-de-recherche-eightsevenfour-agronomy : Institut National de la Recherche Agronomique, Unité de Recherche 874 Agronomy : fr : National Institute of Agronomic Research, Research Unit 874 Agronomy : national-institute-agronomic-research-research-unit-874-agronomy
universidad-santo-tomas-laboratorio-de-ecologia-y-cambio-climatico : Universidad Santo Tomas Laboratorio de Ecologia y Cambio Climatico : es : Santo Tomas University Ecology and Climate Change Laboratory : santo-tomas-university-ecology-climate-change-laboratory
technische-universitat-munchen-institut-fur-astronomische-und-physikalische-geodasie : Technische Universität München Institut für Astronomische und Physikalische Geodäsie : de : Technical University of Munich Institute of Astronomical and Physical Geodesy : technical-university-munich-institute-astronomical-physical-geodesy
university-hamburg-institut-fur-unternehmensforschung : University of Hamburg Institut für Unternehmensforschung : de : University of Hamburg Institute for Enterprise Research : university-hamburg-institute-enterprise-research
hospital-general-universitario-gregorio-maranon-division-clinical-microbiology-infectious-disease : Hospital General Universitario Gregorio Marañón Division of Clinical Microbiology and Infectious Disease : es : University Hospital Gregorio Marañón Division of Clinical Microbiology and Infectious Disease : university-hospital-gregorio-maranon-division-clinical-microbiology-infectious-disease
university-liege-astrophysics-geophysics-institute : Université de Liège Astrophysics and Geophysics Institute : fr : University of Liège Astrophysics and Geophysics Institute : university-liege-astrophysics-geophysics-institute
universidade-sao-paulo-instituto-de-fisica : Universidade de São Paulo Instituto de Física : pt : University of São Paulo Institute of Physics : university-sao-paulo-institute-physics
centre-national-d-etudes-spatiales : Centre National D'études Spatiales : fr : National Center for Space Studies : national-center-space-studies
agenzia-spaziale-italiana : Agenzia Spaziale Italiana : it : Italian Space Agency : italian-space-agency
instituto-nacional-pesquisas-espaciais : Instituto Nacional de Pesquisas Espaciais : pt : National Institute of Space Research : national-institute-space-research
max-planck-institute-meteorologie : Max-Planck-Institut für Meteorologie : de : Max Planck Institute for Meteorology : max-planck-institute-meteorology
centre-national-recheres-meteorologiques : Centre National de Recherches Météorologiques : fr : National Center for Meteorological Research : national-center-meteorological-research
universite-catholique-de-louvain-earth-life-institute : Université catholique de Louvain Earth and Life Institute : fr : Catholic University of Louvain Earth and Life Institute : catholic-university-louvain-earth-life-institute
institut-pierre-simon-laplace : Institut Pierre Simon Laplace : fr : Pierre Simon Laplace Institute : pierre-simon-laplace-institute
universitat-barcelona-departament-dastronomia-i-meteorologia : Universitat de Barcelona Departament d’Astronomia i Meteorologia : ca : University of Barcelona Department of Astronomy and Meteorology : university-barcelona-department-astronomy-meteorology
centro-desarrollo-tecnologico-industrial : Centro para el Desarrollo Tecnológico Industrial : es : Center for Industrial Technological Development : center-industrial-technological-development
comision-nacional-actividades-espaciales : Comisión Nacional de Actividades Espaciales : es : National Commission on Space Activities : national-commission-space-activities
instituto-nazionale-geofisica-vulcanologia : Instituto Nazionale di Geofisica e Vulcanologia : it : National Institute of Geophysics and Volcanology : national-institute-geophysics-volcanology
instituto-nacional-de-ecologia : Instituto Nacional de Ecologia : es : National Institute of Ecology : national-institute-ecology
el-colegio-de-mexico-center-demographic-urban-environmental-studies : El Colegio de México Center for Demographic, Urban and Environmental Studies : es : The College of Mexico Center for Demographic, Urban and Environmental Studies : college-mexico-center-demographic-urban-environmental-studies
laboratoire-detudes-en-geophysique-et-oceanographie-spatiales : Laboratoire d'Etudes en Géophysique et Océanographie Spatiales : fr : Laboratory of Geophysical and Oceanographic Studies : laboratory-geophysical-oceanographic-studies
leibniz-institut-fur-ostseeforschung-warnemunde : Leibniz-Institut für Ostseeforschung Warnemünde : de : Leibniz Institute for Baltic Sea Research Warnemünde : leibniz-institute-baltic-sea-research-warnemunde
centro-de-investigaciones-del-mar-y-la-atmosfera : Centro de Investigación del Mar y la Atmósfera : es : Sea and Atmosphere Research Center : sea-atmosphere-research-center
universidad-de-buenos-aires : Universidad de Buenos Aires : es : Buenos Aires' University : buenos-aires-university
planbureau-voor-de-leefomgeving : Planbureau voor de Leefomgeving : nl : Netherlands Environmental Assessment Agency : nederlands-environmental-assessment-agency
centro-investigaciones-economia-mundial : Centro de Investigaciones de la Economía Mundial : es : Center for Research in the World Economy : center-research-world-economy
energieonderzoek-centrum-nederland : Energieonderzoek Centrum Nederland : nl : Energy research Centre of the Netherlands : energy-research-centre-nederlands
potsdam-institut-klimafolgenforschung : Potsdam-Institut für Klimafolgenforschung : de : Potsdam Institute for Climate Impact Research : potsdam-institute-climate-impact-research
koninklijk-nederlands-meteorologisch-instituut : Koninklijk Nederlands Meteorologisch Instituut : nl : Royal Dutch Meteorological Institute : royal-dutch-meteorological-institute
universidad-nacional-de-la-plata : Universidad Nacional de La Plata : es : National University of La Plata : national-university-la-plata
universidad-nacional-del-comahue : Universidad Nacional del Comahue : es : National University of Comahue : national-university-comahue
deutsche-forschungsanstalt-fur-lebensmittelchemie : Deutsche Forschungsanstalt für Lebensmittelchemie : de : German Research Institute for Food Chemistry : german-research-institute-food-chemistry
universitat-hohenheim-landesanstalt-fur-landwirtschaftliche-chemie : Universität Hohenheim Landesanstalt für Landwirtschaftliche Chemie : de : University of Hohenheim National Institute for Agricultural Chemistry : university-hohenheim-national-institute-agricultural-chemistry
universitat-hohenheim : Universität Hohenheim : de : University of Hohenheim : university-hohenheim
universitat-hohenheim-institute-landscape-plant-ecology : Universität Hohenheim Institute for Landscape and Plant Ecology : de : University of Hohenheim Institute for Landscape and Plant Ecology : university-hohenheim-institute-landscape-plant-ecology
johann-heinrich-von-thunen-institute-federal-research-institute-rural-areas-forestry-fisheries : Johann Heinrich von Thunen-Institute, Federal Research Institute for Rural Areas, Forestry and Fisheries : de : Johann Heinrich von Thunen Institute, Federal Research Institute for Rural Areas, Forestry and Fisheries : johann-heinrich-von-thunen-institute-federal-research-institute-rural-areas-forestry-fisheries
hospital-del-mar-barcelona-psychiatry-department : Hospital del Mar Psychiatry Department : es : Hospital of the Sea Psychiatry Department : hospital-sea-psychiatry-department
servicios-de-salud-de-tamaulipas : Servicios de Salud de Tamaulipas : es : Health Services of Tamaulipas : health-services-tamaulipas
pablo-kuri-morales : Pablo Kuri Morales : es : Pablo Kuri Morales : pablo-kuri-morales
university-evora-centro-de-investigacao-em-biodiversidade-e-recursos-geneticos : University of Évora Centro de Investigação em Biodiversidade e Recursos Genéticos : pt : University of Évora Center for Research on Biodiversity and Genetic Resources : university-evora-center-research-biodiversity-genetic-resources
laboratoire-doceanographie-et-du-climat : Laboratoire d'Océanographie et du Climat : fr : Laboratory of Oceanography and Climate : laboratory-oceanography-climate
meteorology-service-catalonia : Servei Meteorològic de Catalunya : ca : Meteorological Service of Catalonia : meteorological-service-catalonia
instituto-de-ecologia-ac : Instituto de Ecología, A.C. : es : Institute of Ecology, A.C. : institute-ecology-ac
institut-national-de-la-recherche-agronomique : Institut National de la Recherche Agronomique : fr : The National Institute of Agronomic Research : national-institute-agronomic-research
jose-luis-robles-lopez : José Luis Robles Lopez : es : José Luis Robles Lopez : jose-luis-robles-lopez
instituto-de-diagnostico-y-referencia-epidemiologicos : Instituto de Diagnóstico y Referencia Epidemiológicos : es : Institute of Epidemiological Diagnosis and Reference : institute-epidemiological-diagnosis-reference
institut-louis-malarde : Institut Louis-Malardé : fr : Institute of Louis-Malardé : institute-louis-malarde
ecole-polytechnique-department-economics : Ecole Polytechnique Department of Economics : fr : Ecole Polytechnique Department of Economics : ecole-polytechnique-department-economics
instituto-de-pesquisa-ambiental-da-amazonia : Instituto de Pesquisa Ambiental da Amazônia : pt : Institute of Environmental Research of the Amazon : institute-environmental-research-amazon
universidade-federal-de-minas-gerais : Universidade Federal de Minas Gerais : pt : Federal University of Minas Gerais : federal-university-minas-gerais
universidade-federal-de-minas-gerais-centro-de-sensoriamento-remoto : Universidade Federal de Minas Gerais Centro de Sensoriamento Remoto : pt : Federal University of Minas Gerais Center for Remote Sensing : federal-university-minas-gerais-center-remote-sensing
universidade-federal-de-minas-gerais-centro-de-desenvolvimento-e-planejamento-regional : Universidade Federal de Minas Gerais Centro de Desenvolvimento e Planejamento Regional : pt : Federal University of Minas Gerais Center for Regional Development and Planning : federal-university-minas-gerais-center-regional-development-planning
fondazione-eni-enrico-mattei : Fondazione Eni Enrico Mattei : it : Fondazione Eni Enrico Mattei : fondazione-eni-enrico-mattei
laboratoire-des-sciences-du-climat-et-de-lenvironnement : Laboratoire des Sciences du Climat et de l'Environnement : fr : Laboratory of Climate and Environmental Sciences : laboratory-climate-environmental-sciences
universite-de-cergy-pontoise : Université de Cergy-Pontoise : fr : University of Cergy-Pontoise : university-cergy-pontoise
ecole-normale-superieure : École normale supérieure : fr : École Normale Supérieure : ecole-normale-superieure
commissariat-a-lenergie-atomique-et-aux-energies-alternatives : Commissariat à l’énergie atomique et aux énergies alternatives : fr : Office of Atomic Energy and Alternative Energies : fice-atomic-energy-alternative-energies
universidad-de-buenos-aires-catedra-de-bioquimica : Universidad de Buenos Aires Cátedra de Bioquimica : es : University of Buenos Aires Chair of Biochemistry : university-buenos-aires-chair-biochemistry
observatoire-de-paris : Observatoire de Paris : fr : Observatory of Paris : observatory-paris
fondazione-edmund-mach : Fondazione Edmund Mach : it : Edmund Mach Foundation : edmund-mach-foundation
alpen-adria-universitat-klagenfurt-institute-social-ecology : Alpen-Adria-Universität Klagenfurt Institute of Social Ecology : de : University of Klagenfurt Institute of Social Ecology : university-klagenfurt-institute-social-ecology
laboratoire-atmospheres-milieux-observations-spatiales : Laboratoire Atmosphères, Milieux, Observations Spatiales : fr : Laboratory Atmospheres, Spatial Observations : laboratory-atmospheres-spatial-observations
institu-national-des-sciences-de-lunivers : Institut National des Sciences de l'univers : fr : National Institute of Sciences of the Universe : national-institute-sciences-universe
consejo-nacional-de-investigaciones-cientificas-y-tecnicas : Consejo Nacional de Investigaciones Científicas y Técnicas : es : National Council for Scientific and Technical Research : national-council-scientific-technical-research
pontificia-universidad-catolica-argentina : Pontificia Universidad Católica Argentina : es : Pontifical Catholic University of Argentina : pontifical-catholic-university-argentina
centro-investigacion-enfermedades-tropicales : Centro de Investigación en Enfermedades Tropicales : es : Center for Research on Tropical Diseases : center-research-tropical-diseases
centre-europeen-de-recherche-formation-avancee-calcul-scientifique : Centre Européen de Recherche et de Formation Avancée en Calcul Scientifique : fr : European Centre for Research and Advanced Training in Scientific Computation : european-centre-research-advanced-training-scientific-computation
universite-versailles-saint-quentin-en-yvelines : Université de Versailles Saint-Quentin-en-Yvelines : fr : Versailles Saint-Quentin-en-Yvelines University : versailles-saint-quentin-en-yvelines-university
hospital-la-colombiere : Centre Hospitalier Universitaire de Montpellie : fr : the University Hospital of Montpellier : university-hospital-montpellier
institut-national-de-la-sante-et-de-la-recherche-medicale : Institut National de la Santé et de la Recherche Médicale : fr : National Institute of Health and Medical Research : national-institute-health-medical-research
universitat-bern-geographischen-institut : Geographischen Institut der Universität Bern : de : Geographical Institute of the University of Bern : geographical-institute-university-bern
el-colegia-de-la-frontera-sur : El Colegio de la Frontera Sur : es : The South Border College : south-border-college
institut-de-recherche-pour-le-developpement : Institut de Recherche pour le Développement : fr : French Research Institute for Development : french-research-institute-development
universite-montpellier-ii : Universite Montpellier II : fr : Montpellier 2 University : montpellier-2-university
institut-francais-de-recherche-pour-lexploitation-de-la-mer : Institut Français de Recherche pour l'exploitation de la Mer : fr : French Research Institute for the Exploitation of the Sea : french-research-institute-exploitation-sea
centre-de-recherche-halieutique-mediterraneenne-et-tropicale : Centre de Recherche Halieutique Méditerranéenne et Tropicale : fr : Mediterranean and Tropical Fisheries Research Center : mediterranean-tropical-fisheries-research-center
universite-lausanne-centre-de-recherche-sur-le-lenvironnement-terrestre : Université de Lausanne Centre de recherche sur l'environnement terrestre : fr : University of Lausanne Center for Research on the Terrestrial Environment : university-lausanne-center-research-terrestrial-environment
institut-de-veille-sanitaire : Institut de Veille Sanitaire : fr : Institute of Health Watch : institute-health-watch
instituto-de-diagnostico-ambiental-y-estudios-del-agua : Instituto de Diagnóstico Ambiental y Estudios del Agua : es : Institute of Environmental Diagnosis and Water Studies : institute-environmental-diagnosis-water-studies
institut-fur-physik-der-atmosphare : Institut für Physik der Atmosphäre : de : Institute of Atmospheric Physics : institute-atmospheric-physics
agenzia-nazionale-per-le-nuove-tecnologie-lenergia-e-lo-sviluppo-economico-sostenibile : Agenzia Nazionale per le Nuove Tecnologie, l'energia e lo Sviluppo Economico Sostenibile : it : National Agency for New Technologies, Energy and Sustainable Economic Development : national-agency-new-technologies-energy-sustainable-economic-development
meteorologisk-institutt : Meteorologisk Institutt : no : Meteorological Department : meteorological-department
universitat-bern-astronomical-institute : Universitat Bern Astronomical Institute : fr : University of Bern Astronomical Institute : university-bern-astronomical-institute
consejo-superior-de-investigationes-cientificas : Consejo Superior de Investigationes Cientificas : es : Higher Council for Scientific Research : higher-council-scientific-research
instituto-nacional-de-salud-publica : Instituto Nacional de Salud Pública : es : National Institute of Public Health : national-institute-public-health
agence-nationale-de-recherche : Agence National de Recherche : fr : National Research Agency : national-research-agency
universidad-de-chile-instituto-de-nutricion-y-tecnologia-de-alimentos : Universidad de Chile Instituto de Nutrición y Tecnología de Alimentos : es : University of Chile Institute of Nutrition and Food Technology : university-chile-institute-nutrition-food-technology
deutscher-wetterdienst : Deutscher Wetterdienst : de : German Weather Service : german-wear-service
ministere-de-la-defense : Ministère de la Défense : fr : Department of Defense : department-defense
institut-pasteur : Institut Pasteur : fr : Pastor Institute : pastor-institute
institut-pasteur-department-virology : Institut Pasteur Department of Virology : fr : Pastor Institute Department of Virology : pastor-institute-department-virology
meteo-france : Météo-France : fr : Meteo France : meteo-france
hospital-general-universitario-gregorio-maranon : Hospital General Universitario Gregorio Marañón : es : University Hospital Gregorio Marañón : university-hospital-gregorio-maranon
instituto-de-investigacion-sanitaria-gregorio-maranon : Instituto de Investigación Sanitaria Gregorio Marañón : es : Gregorio Maranon Institute of Health Research : gregorio-maranon-institute-health-research
universidad-complutense-de-madrid : Universidad Complutense de Madrid : es : Complutense University of Madrid : complutense-university-madrid
ciber-de-engermadades-respiratorias : CIBER de Enfermedades Respiratorias : es : CIBER of Respiratory Diseases : ciber-respiratory-diseases
universidade-de-santiago-de-compostela-instituto-de-investigaciones-tecnologicas : Universidade de Santiago de Compostela Instituto de Investigaciones Tecnológicas : es : University of Santiago de Compostela Institute of Technological Research : university-santiago-de-compostela-institute-technological-research
universidade-de-santiago-de-compostela-instituto-de-acuicultura : Universidade de Santiago de Compostela Instituto de Acuicultura : es : University of Santiago de Compostela Institute of Aquaculture : university-santiago-de-compostela-institute-aquaculture
laboratoire-de-biogeochimie-isotopique : Laboratoire de Biogéochimie Isotopique : fr : Laboratory of Isotopic Biogeochemistry : laboratory-isotopic-biogeochemistry
bundesministerium-fur-bildung-und-forschung : Bundesministerium für Bildung und Forschung : de : Federal Ministry of Education and Research : federal-ministry-education-research
universitat-autonoma-de-barcelona : Universitat Autònoma de Barcelona : es : Autonomous University of Barcelona : autonomous-university-barcelona
universitat-autonoma-de-barcelona-centre-de-recerce-ecologia-i-apicacios-forestals : Universitat Autònoma de Barcelona Centre de Recerce Ecològia i Apicacios Forestals : es : Autonomous University of Barcelona Center Recerce Forest Ecology and Apicacios : autonomous-university-barcelona-center-recerce-forest-ecology-apicacios
universite-de-liege-departement-de-geographie : Université de Liège Département de Géographie : fr : University of Liège Department of Geography : university-liege-department-geography
vrije-universiteit-brussel : Vrije Universiteit Brussel : nl : Vrije Universiteit Brussel : vrije-universiteit-brussel
vrije-universiteit-brussel-departement-geografie : Vrije Universiteit Brussel Departement Geografie : nl : Vrije Universiteit Brussel Department of Geography : vrije-universiteit-brussel-department-geography
vrije-universiteit-brussel-earth-system-science : Vrije Universiteit Brussel Earth System Science : nl : Vrije Universiteit Brussel Earth System Science : vrije-universiteit-brussel-earth-system-science
universite-de-liege : Université de Liège : fr : University of Liège : university-liege
potsdam-institut-fur-klimafolgenforschung-research-domain-climate-impacts-vulnerabilities : Potsdam-Institut für Klimafolgenforschung Research Domain of Climate Impacts and Vulnerabilities : de : Potsdam Institute for Climate Impact Research Research Domain of Climate Impacts and Vulnerabilities : potsdam-institute-climate-impact-research-research-domain-climate-impacts-vulnerabilities
istituto-agrario-di-san-michele-alladige : Istituto Agrario di San Michele all'Adige : it : Agricultural Institute of San Michele all'Adige : agricultural-institute-san-michele-alladige
centre-de-cooperation-internationale-en-recherche-agronomique-pour-le-developpement : Centre de coopération internationale en recherche agronomique pour le développement : fr : Center for International Cooperation in Agronomic Research for Development : center-international-cooperation-agronomic-research-development
universidade-nova-de-lisboa : Universidade Nova de Lisboa : pt : New University of Lisbon : new-university-lisbon
universiteit-antwerpen-departement-biologie : Universiteit Antwerpen Departement Biologie : nl : University of Antwerp Department of Biology : university-antwerp-department-biology
universidade-nova-de-lisboa-faculdade-de-ciencias-e-tecnologia : Universidade Nova de Lisboa Faculdade de Ciências e Tecnologia : pt : New University of Lisbon Faculty of Science and Technology : new-university-lisbon-faculty-science-technology
universiteit-antwerpen : Universiteit Antwerpen : nl : University of Antwerp : university-antwerp
centro-agronomico-tropical-de-investigacion-y-ensenanza : Centro Agronómico Tropical de Investigación y Enseñanza : es : Tropical Agronomic Center for Research and Teaching : tropical-agronomic-center-research-teaching
universidade-de-evora : Universidade de Évora : pt : University of Évora : university-evora
universidade-de-evora-catedra-rui-nabeiro : Universidade de Évora Cátedra Rui Nabeiro : pt : University of Évora Rui Nabeiro Chair : university-evora-rui-nabeiro-chair
istituto-per-i-sistemi-agricoli-e-forestali-del-mediterraneo : Istituto per i sistemi Agricoli e Forestali del Mediterraneo : it : Institute for Agricultural and Forestry systems of the Mediterranean : institute-agricultural-forestry-systems-mediterranean
institut-national-de-la-recherche-agronomique-ecologie-ecophysiologie-forestieres : Institut National de la Recherche Agronomique Ecologie et Ecophysiologie Forestières : fr : National Institute of Agricultural Research Forest Ecology and Ecophysiology : national-institute-agricultural-research-forest-ecology-ecophysiology
universitat-de-les-illes-balears : Universitat de les Illes Balears : es : University of the Balearic Islands : university-balearic-islands
instituto-mediterraneo-de-estudios-avanzados : Instituto Mediterráneo de Estudios Avanzados : es : Mediterranean Institute of Advanced Studies : mediterranean-institute-advanced-studies
instituto-mediterraneo-de-estudios-avanzados-global-change-research-department : Instituto Mediterráneo de Estudios Avanzados Global Change Research Department : es : Mediterranean Institute of Advanced Studies Global Change Research Department : mediterranean-institute-advanced-studies-global-change-research-department
universidad-santo-tomas : Universidad Santo Tomas : es : Santo Tomas University : santo-tomas-university
linstitut-ecologie-environnement : l'Institut Écologie Environnement : fr : The Ecology Environment Institute : ecology-environment-institute
universite-du-quebec-a-montreal : Université du Québec à Montréal : fr : University of Quebec in Montreal : university-quebec-montreal
nederlands-instituut-voor-ecologie : Nederlands Instituut voor Ecologie : nl : Dutch Institute for Ecology : dutch-institute-ecology
laboratoire-doceanographie-de-villefranche-sur-mer : Laboratoire d'Océanographie de Villefranche-sur-Mer : fr : Laboratory of Oceanography of Villefranche-sur-Mer : laboratory-oceanography-villefranche-sur-mer
universite-du-quebec-a-montreal-departement-des-sciences-biologiques : Université du Québec à Montréal Département des Sciences biologiques : fr : University of Quebec in Montreal Department of Biological Sciences : university-quebec-montreal-department-biological-sciences
centrum-voor-estuariene-en-mariene-ecologie : Centrum voor Estuariene en Mariene Ecologie : nl : Centre for Estuarine and Marine Ecology : centre-estuarine-marine-ecology
universitat-autonoma-de-barcelona-centre-de-estudis-avancats-de-blanes : Universitat Autònoma de Barcelona Centre d’Estudis Avançats de Blanes : es : Autonomous University of Barcelona Centre for Advanced Studies of Blanes : autonomous-university-barcelona-centre-advanced-studies-blanes
consejo-superior-de-investigationes-cientificas-institute-marine-sciences : Consejo Superior de Investigationes Cientificas Institute of Marine Sciences : es : Higher Council for Scientific Research Institute of Marine Sciences : higher-council-scientific-research-institute-marine-sciences
technische-universitat-munchen : Technische Universität München : de : Technical University of Munich : technical-university-munich
