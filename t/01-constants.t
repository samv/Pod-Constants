#!/usr/bin/perl -w

use strict;
use Test::More tests => 6;

use vars qw($section_1 $section_2);

use_ok(
       "Pod::Constants",
       section_1 => \$section_1,
       -trim => 1,
       section_2 => \$section_2
      );

BEGIN {
    push @INC, "t";
};
use Cheese;

is($section_1, "Legalise Cannabis!\n\n", "no trim from main");
is($section_2, "42", "with trim from main");
is($Cheese::foo, "detcepxe", "From module");
like(`perl -c t/Cheese.pm 2>&1`, qr/syntax OK/, "perl -c module");
like(`perl -c t/cheese.pl 2>&1`, qr/syntax OK/, "perl -c script");

=head2 section_1

Legalise Cannabis!

=head2 section_2

42

=cut
