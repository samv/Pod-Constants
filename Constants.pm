package Pod::Constants;

=head1 NAME

Pod::Constants - Include constants from POD

=head1 SYNOPSIS

 use vars qw($myvar);
 use Pod::Constants -trim => 1,
     'Pod Section Name' => \$myvar;

 =head2 Pod Section Name

 This string will be loaded into $myvar

 =cut

=head1 DESCRIPTION

This module is for when you have constants in your code, but you want
to keep them in the documentation so that when they change you only
have to update them in one place.

Pod::Constants uses Pod::Parser to do the parsing of the source file.
It has to open the source file it is called from, and does so directly
either by lookup in %INC or from $0 if the caller is "main".

I have made this code only allow the "Pod Section Name" to match
`head1', `head2' and `item' POD sections.  If you have a good reason
why you think it should match other POD sections, drop me a line and
if I'm convinced I'll put it in the standard version.

=cut

use 5.004;
use strict;

use base qw(Pod::Parser Exporter);
use Data::Dumper;

# Global parser state variables
use vars qw(%wanted_pod_tags %trim $active $VERSION);

$VERSION = "0.02";

# Pod::Parser overloaded command
sub command {
    my ($parser, $command, $paragraph, $line_num) = @_;

    $paragraph =~ s/^\s*|\s*$//gs;

    if ($command =~ m/^(head[12]|item)$/) {
	if (exists $wanted_pod_tags{$paragraph}) {
	    $active = $paragraph;
	}
    } else {
	$active = undef;
    }
}

# Pod::Parser overloaded verbatim
sub verbatim {
    my ($parser, $paragraph, $line_num) = @_;

    if (defined $active) {
	$paragraph =~ s/^\s*|\s*$//gs if $trim{$active};
	${$wanted_pod_tags{$active}} = $paragraph;
	$active = undef;
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
    	print "Caller: ".caller()."\n";
	my $module = caller;
	$module =~ s|::|/|g;
	$module .= ".pm";
    	print "module: ".$module."\n";
	$source_file = $INC{$module};
    	print "inc(.): ".$source_file."\n";
    }
    print "\$0: $0\n";
    $source_file ||= $0;
    print "final source file: $source_file\n";

    my $parser = $class->new();
    open CLASSFILE, "<$source_file"
	or die "cannot open $source_file for reading; $!";

    %wanted_pod_tags = %trim = ();
    $active = undef;
    my ($trim);

    while (my ($pod_tag, $var) = splice @args, 0, 2) {
	if (lc($pod_tag) eq "-trim") {
	    $trim = $var;
	} else {
	    if (ref $var eq "SCALAR") {
		$wanted_pod_tags{$pod_tag} = $var;
		$trim{$pod_tag} = 1 if $trim;
	    } else {
		die ("Sorry - can only import POD sections into scalars "
		     ."importing $pod_tag into ".caller);
	    }
	}
    }

    $parser->parse_from_filehandle(\*CLASSFILE, \*STDOUT);

    close CLASSFILE;
}

=head1 AUTO MODULE VERSIONS

Put this in your module code for automatic POD/Makefile.PL updating:

   =head2 MODULE RELEASE

   $VERSION = 1.05

   =cut

   use vars qw($VERSION);
   use Pod::Constants -trim => 1, 'MODULE RELEASE' => \$VERSION;
   BEGIN { $VERSION =~ s/^\$VERSION\s*=\s*// };

=head1 AUTHOR

Sam Vilain, <sam@vilain.net>

=head1 BUGS/TODO

Is there any value in being able to import structured data from POD
sections, perhaps?  Maybe extracting tabular information into arrays
or hashes?

What about doing nasty things to the caller's symbol table, so they
don't need to "use vars"?

=cut

1;
