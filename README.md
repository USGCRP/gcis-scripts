These are miscelleneous client side scripts for interacting with the Global Change Information System (GCIS).

Many scripts in this collection are copied and pasted from each other and other places.


## Setup


 - Create a repos dir  
   `mkdir repos && cd repos`
 - Clone the repos:  
   `git clone https://github.com/USGCRP/gcis-pl-client`  
   `git clone https://github.com/USGCRP/gcis-scripts`
 - Add the libs to `PERL5LIB`  
   `echo export PERL5LIB=$PERL5LIB:/home/testuser/repos/gcis-pl-client/lib/:/home/testuser/repos/gcis-scripts/lib/ >>~/.bashrc`
 - Install Perlbrew and the perl version  
   `\curl -L https://install.perlbrew.pl | bash`  
   `perlbrew install perl-5.20.3` #long running  
   `perlbrew switch perl-5.20.3`
 - Install Mojolicious  
   `curl -L https://cpanmin.us | perl - -M https://cpan.metacpan.org -n Mojolicious`
 - Install CPAN modules, as needed.  
   `cpan install [Module::Name::Here]`

