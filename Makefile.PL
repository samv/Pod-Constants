use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Pod::Constants',
    'VERSION_FROM'	=> 'Constants.pm', # finds $VERSION
    'PREREQ_PM'		=> { Pod::Parser => 1.13 },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Constants.pm', # retrieve abstract from module
       AUTHOR     => 'Sam Vilain <sam@vilain.net>') : ()),
);
