package Posy::Plugin::Canonical;
use strict;

=head1 NAME

Posy::Plugin::Canonical - Posy plugin to force redirect to canonical URL.

=head1 VERSION

This describes version B<0.52> of Posy::Plugin::Canonical.

=cut

our $VERSION = '0.52';

=head1 SYNOPSIS

    @plugins = qw(Posy::Core
		  Posy::Plugin::Canonical);

=head1 DESCRIPTION

Have Posy force a redirect if a URI is not in canonical form with
respect to index.* component, trailing slash, or flavour extension.

This replaces the parse_path method.

=cut

=head1 Flow Action Methods

Methods implementing actions.

=head2 parse_path

Parse the path info.  This calls the parent parse_path method and then
redirects to the canonical path if the original path isn't canonical
(and we are in dynamic mode).

=cut
sub parse_path {
    my $self = shift;
    my $flow_state = shift;

    $self->SUPER::parse_path($flow_state);
    my $path_info = $self->{path}->{info};
    $self->debug(1, "Canonical: path_info='$path_info'");
    if ($self->{dynamic}
	&& !$self->{path}->{error}
	&& ($self->{path}->{type} =~ /entry/
	    || $self->{path}->{type} =~ /category/))
    {
	# Write the desired canonical URI, then check if the
	# original path is canonical; if not, redirect.
	my $can_path;

	# categories
	if ($self->{path}->{type} eq 'category'
	    or ($self->{path}->{type} eq 'entry'
		and $self->{path}->{basename} eq 'index'))
	{
	    # canonical: dir with slash
	    $can_path = '/' . $self->{path}->{cat_id} . '/';
	    # if this is not the default flavour, put index.foo at end
	    if ($self->{path}->{flavour} ne $self->{config}->{flavour})
	    {
		$can_path .= 'index.' . $self->{path}->{flavour};
	    }
	}
	# because the top index page has often to be treated specially,
	# only redirect for this if enabled.
	elsif ($self->{redirect_top}
	       and ($self->{path}->{type} eq 'top_category'
		    or ($self->{path}->{type} eq 'top_entry'
			and $self->{path}->{basename} eq 'index')
		   )
	      )
	{
	    # canonical: slash
	    $can_path = '/';
	    # if this is not the default flavour, put index.foo at end
	    if ($self->{path}->{flavour} ne $self->{config}->{flavour})
	    {
		$can_path .= 'index.' . $self->{path}->{flavour};
	    }
	}
	elsif ($self->{path}->{type} eq 'entry'
	    and $self->{path}->{basename} ne 'index')
	{
	    # canonical: dir with slash then entry.foo
	    $can_path = '/' . $self->{path}->{cat_id} . '/'
		. $self->{path}->{basename}
		. '.'
		. $self->{path}->{flavour};
	}
	elsif ($self->{path}->{type} eq 'top_entry'
	    and $self->{path}->{basename} ne 'index')
	{
	    # canonical: dir with slash then entry.foo
	    $can_path = '/' 
		. $self->{path}->{basename}
		. '.'
		. $self->{path}->{flavour};
	}
	else # some other type -- leave it alone
	{
	    $can_path = $self->{path}->{info};
	}
	$self->debug(1, "Canonical: path='$can_path'");

	if ($can_path ne $self->{path}->{info})
	{
	    my $uri = $self->{url} . $can_path;
	    $uri .= "?" . $ENV{QUERY_STRING} if $ENV{QUERY_STRING};
	    $self->redirect($flow_state, $uri);
	}
    }

    1;
} # parse_path

=head1 Helper Methods

Methods which can be called from elsewhere.

=head2 redirect

    $self->redirect($flow_state, $uri);

Redirect to the given URI.

=cut
sub redirect {
    my $self = shift;
    my $flow_state = shift;
    my $uri = shift;

    $flow_state->{stop} = 1;
    if ($self->{dynamic})
    {
	$self->debug(1, "redirecting to '$uri'");

	$self->print_header(content_type=>'text/html',
	    status=>301,
	    extra=>"Location: $uri");
	print "<html><body>\n";
	print "<p>Redirecting to <a href=\"$uri\">$uri</a>.\n";
	print "</body></html>\n";

	return 1;
    }
} # redirect

=head1 INSTALLATION

Installation needs will vary depending on the particular setup a person
has.

=head2 Administrator, Automatic

If you are the administrator of the system, then the dead simple method of
installing the modules is to use the CPAN or CPANPLUS system.

    cpanp -i Posy::Plugin::Canonical

This will install this plugin in the usual places where modules get
installed when one is using CPAN(PLUS).

=head2 Administrator, By Hand

If you are the administrator of the system, but don't wish to use the
CPAN(PLUS) method, then this is for you.  Take the *.tar.gz file
and untar it in a suitable directory.

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you're on a platform (like DOS or Windows) that doesn't like the
"./" notation, you can do this:

   perl Build.PL
   perl Build
   perl Build test
   perl Build install

=head2 User With Shell Access

If you are a user on a system, and don't have root/administrator access,
you need to install Posy somewhere other than the default place (since you
don't have access to it).  However, if you have shell access to the system,
then you can install it in your home directory.

Say your home directory is "/home/fred", and you want to install the
modules into a subdirectory called "perl".

Download the *.tar.gz file and untar it in a suitable directory.

    perl Build.PL --install_base /home/fred/perl
    ./Build
    ./Build test
    ./Build install

This will install the files underneath /home/fred/perl.

You will then need to make sure that you alter the PERL5LIB variable to
find the modules, and the PATH variable to find the scripts (posy_one,
posy_static).

Therefore you will need to change:
your path, to include /home/fred/perl/script (where the script will be)

	PATH=/home/fred/perl/script:${PATH}

the PERL5LIB variable to add /home/fred/perl/lib

	PERL5LIB=/home/fred/perl/lib:${PERL5LIB}

=head1 REQUIRES

    Test::More

=head1 SEE ALSO

perl(1).
Posy

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 AUTHOR

    Kathryn Andersen (RUBYKAT)
    perlkat AT katspace dot com
    http://www.katspace.com

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2004-2005 by Kathryn Andersen

Original canonicaluri blosxom plugin copyright 2004
Frank Hecker <hecker@hecker.org>, http://www.hecker.org/

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut

1; # End of Posy::Plugin::Canonical
__END__
