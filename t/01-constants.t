#!/usr/bin/perl -w

use strict;
use Test::More tests => 3;

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

is($section_1, "Legalise Cannabis!\n\n", "no trim from main");
is($section_2, "42", "with trim from main");

=head2 section_1

Legalise Cannabis!

=head2 section_2

42

=cut
