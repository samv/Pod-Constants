package Cheese;

use strict;

use vars qw($foo $quux);
use Pod::Constants -debug => 1, -trim => 1,
    foo => \$foo,
    bar => sub { print "GOT HERE\n"; eval "use ReEntrancyTest";
		 print "GOT HERE TOO. \$\@ is `$@'\n"; },
    quux => \$quux,
;

=head1 foo

detcepxe

=head1 bar

=head2 quux

Blah.

=cut

1;
