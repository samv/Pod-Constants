# Copyright (C) 2001 Sam Vilain.  All Rights Reserved.  This module is
# free software. It may be used, redistributed and/or modified under the
# terms of the Perl Artistic License

package Pod::Constants;

=head1 NAME

Pod::Constants - Include constants from POD

=head1 SYNOPSIS

 use vars qw($myvar $VERSION @myarray $html %myhash);

 use Pod::Constants -trim => 1,
     'Pod Section Name' => \$myvar,
     'Version' => sub { eval },
     'Some list' => \@myarray,
     html => \$html,
     'Some hash' => \%myhash;

 =head2 Pod Section Name

 This string will be loaded into $myvar

 =head2 Version

 # This is an example of using a closure.  $_ is set to the
 # contents of the paragraph.  In this example, "eval" is
 # used to execute this code at run time.
 $VERSION = 0.11;

 =head2 Some list

 Each line from this section of the file
 will be placed into a seperate array element.
 For example, this is $myarray[2].

 =head2 Some hash

 This text will not go into the hash, because
 it doesn't look like a definition list.
     key1 => Some value (this will go into the hash)
     var2 => Some Other value (so will this)
     wtf = This won't make it in.

 =head2 %myhash's value after the above:

    ( key1 => "Some value (this will go into the hash)",
      var2 => "Some Other value (so will this)"          )

 =begin html <p>This text will be in $html</p>

 =cut

=head1 DESCRIPTION

This module allows you to specify those constants that should be
documented in your POD, and pull them out a run time in a fairly
arbitrary fashion.

Pod::Constants uses Pod::Parser to do the parsing of the source file.
It has to open the source file it is called from, and does so directly
either by lookup in %INC or by assuming it is $0 if the caller is
"main" (or it can't find %INC{caller()})

=head2 ARBITARY DECISIONS

I have made this code only allow the "Pod Section Name" to match
`headN', `item', `for' and `begin' POD sections.  If you have a good
reason why you think it should match other POD sections, drop me a
line and if I'm convinced I'll put it in the standard version.

For `for' and `begin' sections, only the first word is counted as
being a part of the specifier, as opposed to `headN' and `item', where
the entire rest of the line counts.

=cut

use 5.004;
use strict;

use base qw(Pod::Parser Exporter);
use Data::Dumper;
use Carp;

# Global parser state variables
use vars qw(%wanted_pod_tags %trim $active $VERSION $paragraphs $DEBUG);

sub end_input {
    #my ($parser, $command, $paragraph, $line_num) = (@_);

    return unless $active;

    print "Found end of $active\n" if ($DEBUG);
    my $whereto = $wanted_pod_tags{$active};
    print "\$_ will be set to:\n---\n$paragraphs\n---\n" if ($DEBUG);

    if (ref $whereto eq "CODE") {
	print "calling sub\n" if $DEBUG;
	local ($_) = $paragraphs;
	$whereto->();
	print "done\n" if $DEBUG;
    } elsif (ref $whereto eq "SCALAR") {
	print "inserting into scalar\n" if $DEBUG;
	$$whereto = $paragraphs;
    } elsif (ref $whereto eq "ARRAY") {
	print "inserting into array\n" if $DEBUG;
	@$whereto = split /\n/, $paragraphs;
    } elsif (ref $whereto eq "HASH") {
	print "inserting into hash\n" if $DEBUG;
	# Oh, sorry, should I be in LISP101?
	%$whereto = (map { map { s/^\s*|\s*$//g; $_ }
			       split /=>/, $_ }
		     grep m/^
			    ( (?:[^=]|=[^>])+ )   # scan up to "=>"
			    =>
			    ( (?:[^=]|=[^>])+ =? )# don't allow more "=>"'s
			    $/x,
		     split /\n/, $paragraphs);
    } else { die $whereto }
    $active = undef;
}

# Pod::Parser overloaded command
sub command {
    my ($parser, $command, $paragraph, $line_num) = @_;

    $paragraph =~ s/^\s*|\s*$//gs;
    end_input() if $active;

    my $does_she_want_it_sir;
    if ($command =~ m/^(head\d+|item)$/) {
	if (exists $wanted_pod_tags{$paragraph}) {
	    print "Found $paragraph\n" if ($DEBUG);
	    $active = $paragraph;
	    $paragraphs = undef;
	    $does_she_want_it_sir = "suits you sir";
	}
    } elsif ($command =~ m/^(for|begin)$/) {
	(my $section, $paragraphs) =
	    ($paragraph =~ m/^\s*(\S*)\s*(.*)/s);
	if (exists $wanted_pod_tags{$section}) {
	    print "Found $section\n" if ($DEBUG);
	    $active = $section;
	    $does_she_want_it_sir = "suits you sir";
	}
    } else {
	# nothing
    }
    {local $^W = 0;
    print "Ignoring =$command $paragraph\n"
	if (!$does_she_want_it_sir and $DEBUG)
    }
}

# Pod::Parser overloaded verbatim
sub verbatim {
    my ($parser, $paragraph, $line_num) = @_;

    if (defined $active) {
	$paragraph =~ s/^\s*|\s*$//gs if $trim{$active};
	$paragraphs .= $paragraph;
    }
}

# Pod::Parser overloaded textblock
sub textblock { verbatim @_ }

# This function is called when the user "use"'s us.
sub import {
    my ($class, @args) = (@_);

    # try to guess the source file of the caller
    my $source_file;
    if (caller ne "main") {
	(my $module = caller().".pm") =~ s|::|/|g;
	$source_file = $INC{$module};
    }
    $source_file ||= $0;

    ( -f $source_file )
	or croak ("Cannot find source file (guessed $source_file) for"
		  ." package ".caller());

    import_from_file($source_file, @args);
}

sub import_from_file {
    my ($filename, @what) = (@_);

    my $parser = __PACKAGE__->new();
    open CLASSFILE, "<$filename"
	or die ("cannot open $filename for reading; $!");

    %wanted_pod_tags = %trim = ();

    $active = undef;
    my ($trim, $get_usage);

    # find out what they want imported where
    while (my ($pod_tag, $var) = splice @what, 0, 2) {
	if (lc($pod_tag) =~ "-trim") {
	    $trim = $var;
	} elsif (lc($pod_tag) =~ "-usage") {
	    # an idea for later - automatic "usage"
	    #%wanted_pod_tags{@tags}
	} else {
	    if ((ref $var) =~ /^(?:SCALAR|CODE|ARRAY|HASH)$/) {
		$wanted_pod_tags{$pod_tag} = $var;
		$trim{$pod_tag} = 1 if $trim;
	    } else {
		die ("Sorry - need a plain reference to import POD "
		     ."sections into, not a ref ".(ref $var)
		     ." importing $pod_tag into ".caller());
	    }
	}
    }

    $parser->parse_from_filehandle(\*CLASSFILE, \*STDOUT);

    close CLASSFILE;
}

=head2 CLOSURES AS DESTINATIONS

If the given value is a ref CODE, then that function is called, with
$_ set to the value of the paragraph.  This can be very useful for
applying your own custom mutations to the POD to change it from human
readable text into something your program can use.

After I added this function, I just kept on thinking of cool uses for
it.  The nice, succinct code you can make with it is one of
Pod::Constant's strongest features.

Below are some examples.

=head1 EXAMPLES

=head2 Module Makefile.PL maintenance

Tired of keeping those module Makefile.PL's up to date?

=head2 Example Makefile.PL

 eval "use Pod::Constants";
 ($Pod::Constants::VERSION >= 0.11)
     or die <<EOF
 ####
 ####  ERROR: This module requires Pod::Constants 0.11 or
 ####  higher to be installed.
 ####
 EOF

 my ($VERSION, $NAME, $PREREQ_PM, $ABSTRACT, $AUTHOR);
 Pod::Constants::import_from_file 
     (
      'MyTestModule.pm', -trim => 1,
      'NAME' => sub { $ABSTRACT=$_; ($NAME) = m/(\S+)/ },
      'MODULE RELEASE' => sub { ($VERSION) = m/(\d+\.\d+)/ },
      'DEPENDANCIES' => ($PREREQ_PM = { }),
      'AUTHOR' => \$AUTHOR,
     );

 WriteMakefile
     (
      'NAME'		=> $NAME,
      'PREREQ_PM'        => $PREREQ_PM,
      'VERSION'          => $VERSION,
      ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
       (ABSTRACT         => $ABSTRACT,
        AUTHOR           => $AUTHOR) : ()),
     );

=head2 Corresponding Module

 =head1 NAME

 MyTestModule - Demonstrate Pod::Constant's Makefile.PL usefulness

 =head2 MODULE RELEASE

 This is release 1.05 of this module.

 =head2 DEPENDANCIES

 The following modules are required to make this module:

    Some::Module => 0.02

 =head2 AUTHOR

 Ima Twat <ima@twat.name>

 =cut

 use vars qw($VERSION);
 use Pod::Constants -trim => 1,
     'MODULE RELEASE' => sub { ($VERSION) = m/(\d+\.\d+) or die };

=head1 

=head1 AUTHOR

Sam Vilain, <perl@snowcra.sh>

=head1 BUGS/TODO

I keep thinking it would be nice to be able to import an =item list
into an array or something, eg for a program argument list.  But I'm
not too sure how it would be all that useful in practice; you'd end up
putting the function names for callbacks in the pod or something
(perhaps not all that bad).

Would this be useful?

 Pod::Constants::import(Foo::SECTION => \$myvar);

=cut

BEGIN {
    # 
    Pod::Constants->import
	    (
	     SYNOPSIS => sub {
		 eval pop @{[ grep /^\s*\$VERSION/, split /\n/, $_ ]}
	     }
	    )
};

1.4142;
