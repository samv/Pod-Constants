use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Pod::Constants',
    'VERSION_FROM'	=> "Constants.pm",
    'PREREQ_PM'		=> { Pod::Parser => 1.13,
			     Test::Simple => 0.18,
			   },
    ABSTRACT_FROM   => 'Constants.pm',
    AUTHOR          => 'Sam Vilain <sam@vilain.net>',
);
