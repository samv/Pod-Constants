use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# Extract the version from the file.  I don't think it's right to use
# my own module to do this, so resort to something that should work
# everywhere :-)
my $VERSION;
open FOO, "<Constants.pm" or die $!;
while ( <FOO> ) {
    last if ($VERSION) = m/^\s*\$VERSION\s*=\s*(\d+\.\d+)/;
}
close FOO;

# If this function is not called manually on older versions of
# ExtUtils::MakeMaker, it goes tits up.
ExtUtils::MakeMaker::full_setup();

# "MM" comes from the "ExtUtils::MakeMaker" package
my $mm = MM->new({
    'NAME'		=> 'Pod::Constants',
    'VERSION'		=> $VERSION,
    'PREREQ_PM'		=> { Pod::Parser => 1.13,
			     Test::Simple => 0.18,
			   },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Constants.pm', # retrieve abstract from module
       AUTHOR     => 'Sam Vilain <sam@vilain.net>') : ()),
});

if (open MAKEMAKERISAHORRIDHACK, ">t/perlpath") {
    print MAKEMAKERISAHORRIDHACK $mm->{FULLPERL},"\n";
    close MAKEMAKERISAHORRIDHACK;
} else {
    warn("could not open t/perlpath for writing; $!.  It is remotely "
	 ."possible that some of the test scripts will test against "
	 ."the wrong version of perl.");
}

$mm->flush();

0;
