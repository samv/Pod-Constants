#!/usr/bin/perl -w

use strict;
use Test::More tests => 18;
use Data::Dumper;

use vars qw($section_1 $section_2 $section_3 $section_4 %options);

use_ok(
       "Pod::Constants",
       section_1 => \$section_1,
       -trim => 1,
       section_2 => \$section_2,
       section_3 => sub { tr/[a-z]/[A-Z]/; $section_3 = $_ },
       section_4 => sub { eval },
       'command line parameters' => sub {
	   &Pod::Constants::add_hook
		   (
		    #-trim => 0,
		    '*item' => sub { 
			my ($options, $description) =
			    m/^(.*?)\n\n(.*)/s;
			my (@options, $longest);
			$longest = "";
			for my $option
			    ($options =~ m/\G((?:-\w|--\w+))(?:,\s*)?/g) {
			    push @options, $option;
			    if ( length $option > length $longest) {
				$longest = $option;
			    }
			}
			$longest =~ s/^-*//;
			$options{$longest} =
			    {
			     options => \@options,
			     description => $description,
			    };
		    }
		   )
	       },
      );

ok($Pod::Constants::VERSION,
   "Pod::Constants sets its own VERSION");

BEGIN {
    push @INC, "t";
};
use Cheese;

is($section_1, "Legalise Cannabis!\n\n", "no trim from main");
is($section_2, "42", "with trim from main");
is($section_3, "STICKY BUD", "sub");
is($section_4, "hash cookies", "eval");
is($Cheese::foo, "detcepxe", "From module");
like(`perl -c t/Cheese.pm 2>&1`, qr/syntax OK/, "perl -c module");
like(`perl -c t/cheese.pl 2>&1`, qr/syntax OK/, "perl -c script");

# test the examples on the man page :)
package Pod::Constants;
Pod::Constants->import (SYNOPSIS => sub {
    $main::section_1 = join "\n", map { s/^ //; $_ } split /\n/, $_
});

package main;
open NEWPKG, ">t/TestManPage.pm" or die $!;
# why define your test results when you can read them in from POD?
$section_1 =~ s/myhash\)/myhash %myhash2)/;
$section_1 =~ s/myhash;/myhash, "%myhash\'s value after the above:" => sub { %myhash2 = eval };/;
print NEWPKG "package TestManPage;\n$section_1\n2.818;\n";
close NEWPKG;

use_ok("TestManPage");

is($TestManPage::myvar, 'This string will be loaded into $myvar',
   "man page example 1");
is($TestManPage::VERSION, $Pod::Constants::VERSION,
   "man page example 2");
ok($TestManPage::VERSION,
   "man page example 2 cross-check");
is($TestManPage::myarray[2], 'For example, this is $myarray[2].',
   "man page example 3");
my $ok = 0;
while (my ($k, $v) = each %TestManPage::myhash) {
    if (exists $TestManPage::myhash2{$k}) { $ok ++ };
    if ($v eq $TestManPage::myhash2{$k}) { $ok ++ };
}
is($ok, 4,
   "man page example 4");
is(scalar keys %TestManPage::myhash, 2,
   "man page example 4 cross-check");
is($TestManPage::html, '<p>This text will be in $html</p>',
   "man page example 5");
# supress warnings
$TestManPage::myvar = $TestManPage::html = undef;
@TestManPage::myarray = ();

is($options{foo}->{options}->[0], "-f", "Pod::Constants::add_hook");

=head2 section_1

Legalise Cannabis!

=head2 section_2

42

=head2 section_3

sticky bud

=head2 section_4

$section_4 = "hash cookies"

=cut

=head1 command line parameters

the following command line parameters are supported

=item -f, --foo

This does something cool.

=item -h, --help

This also does something pretty cool.

=cut
