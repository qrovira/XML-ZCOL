package XML::ZCOL;

use warnings;
use strict;
use 5.010;

use Module::Pluggable require=> 1, search_path => 'XML::ZCOL::Parser';

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(zcol_expand);
our @EXPORT = qw(zcol_expand);

=head1 NAME

XML::ZCOL - XML Zen-coding one-liners

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

This module expands expressions similar to those used by zen-coding to build up pieces of XML documents.

    use XML::ZCOL;

    my $foo = zcol_expand("div#page>div.logo+ul#navigation>li*5>a");

    or

    my $zcol = XML::ZCOL->new( parser => "html", options => { indent => "\t" } );

    my $foo = $zcol->expand("div#page>div.logo+ul#navigation>li*5>a");

    # Would generate:
    #<div id="page">
    # <div class="logo"></div>
    # <ul id="navigation">
    #  <li><a href=""></a></li>
    #  <li><a href=""></a></li>
    #  <li><a href=""></a></li>
    #  <li><a href=""></a></li>
    #  <li><a href=""></a></li>
    # </ul>
    #</div>
    ...

=head1 FORMATTERS

=head2 html

An HTML generator, which inlines a few more elements than the more general html parser.

It also has a couple more options to wrap the generated content inside html, head and body tags to generate valid html.

=head3 options

=over

=item indent

A string value that will be used for indentation

=item fullwrap

Add a wrapper that includes html, head and body tags around the generated html.

=item head_title

The title to use in title tag when fullwrap is enabled

=item xml_declaration

Adds the xml declaration tag on the first line

=item xml_encoding

Sets the encoding that will be used on the xml declaration (if xml_declaration is not enabled, this option is ignored)

=back

=head2 xml

Generate XML as a plain string. It does pretty much the same as the html parser, but inlines elements only when they
have no child elements.

=head3 options

=over

=item indent

A string value that will be used for indentation

=item xml_declaration

Adds the xml declaration tag on the first line

=item xml_encoding

Sets the encoding that will be used on the xml declaration (if xml_declaration is not enabled, this option is ignored)

=back

=cut




=head1 EXPORTS

=over

=cut

=item zcol_expand( $template [, $parser [, $options] ] )

Expand an template and return the resulting xml string.

The values for $parser and $options will default to "html" and en empty hash respectively if they are not specified.

=cut
sub zcol_expand
{
    my ( $template, $parser, $options ) = @_;

    return __PACKAGE__->new( parser => $parser, options => $options )->expand( $template );
}

=back

=cut




=head1 METHODS

=over

=cut

=item new( $parser, $options )

Create a new zcol object

=cut
sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $self = {
        parser => $args{parser} // "HTML",
        options => $args{options},
    };

    bless($self, $class);
    return $self;
}

=item $zcol->expand( $template [, $parser [, $options] ] )

Expand an template and return the resulting xml string.

You can optionally specify different parser or options arguments for this expansion.

=cut
sub expand {
    my ($self, $template, $parser, $options) = @_;

    $template  //= "";
    $parser    //= $self->{parser};
    $options   //= $self->{options};

    my ($pm) = grep /::$parser$/, $self->plugins;

    die "Parser '$parser' is not supported."
        unless $pm;

    $pm = $pm->new( %{ $options // {} } );

    local %/ = ();
    $template =~ $pm->grammar();

    if( $self->{debug} || $ENV{XML_ZCOL_GRAMMAR_DEBUG} ) {
        require Data::Dumper;
        say Data::Dumper::Dumper( \%/ );
    }

    return $pm->parse_tree( \%/ );
}

=back

=head1 DEBUGGING

This module disabled debugging due to a strange "Out of memory" bug that appeared on some forking scenarios. This behaviour could not be isolated into a testcase by now, so any patches or scripts to reproduce this bug will be highly appreciated.

To enable debugging, see Regexp::Grammars section on debugging.

Making a long story short, you can add this to the top of the grammar:
    <logfile: gram_log >
    <debug: on>

=cut

=head1 TODO

=over

=item Implement classfull parsers

This module could be greatly improved by using classfull xml/html generation through any of the many XML libraries available on CPAN, as well as by using Conway's Regexp::Grammars ability to generate classfull trees at parse-time.

By now, and to keep dependences to the minimum, it generates raw string data instead.

=item Abstract parsers on a separate class

This will be the first major step towards publication on CPAN. Formatter API should be clearly defined and abstracted into a pluggable class (e.g: through Module::Pluggable or via module registration hooks).

Once this is done, a much saner design of the nearly-the-same html and xml string parsers will be possible

=item Enhance grammar to support parameters on attributes

This should not be complicated, since it is already mostly the same. Special attention should be paid to delimiter effect there.

=item Enhance test suite

A must for CPAN publication to make good use of tester's reports.

=item Documentation

Docs should be extended to cover new parser creation (delayed until they are abstracted into isolated classes). Better examples must also be provided: include paramater usage and more complex templates.

=back

=cut

=head1 CHANGES

=over

=item v0.05

=over

=item Debugging now disabled by default. See DEBUGGING for details

=back

=item v0.04

=over

=item Implemented content operator

=item First quick implementation of paramaters

=back

=item v0.03

=over

=item First working version

=back

=back

=cut

=head1 KNOWN BUGS

=over

=item The grammar should be modified to correctly support distillation on grouping. On the first quick group implementation, the required changes made groups after a simple tag delete it from the stack. The current solution generates a children array which may have nested arrays (instead of hashes only), and a trick is done on parsers to get that specific case ok.

=back

=cut

=head1 AUTHOR

Quim Rovira, C<< <quim at rovira.cat> >>

=cut

=head1 BUGS

Please report any bugs or feature requests to C<bug-xml-zcol at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-ZCOL>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=cut

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::ZCOL


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-ZCOL>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-ZCOL>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-ZCOL>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-ZCOL/>

=back

=cut

=head1 ACKNOWLEDGEMENTS

The format used for template expansion has been taken from Zen Coding project in google code.

See http://code.google.com/p/zen-coding/ for more information

=cut

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Quim Rovira.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of XML::ZCOL
