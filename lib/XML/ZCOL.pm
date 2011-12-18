package XML::ZCOL;

use warnings;
use strict;
use 5.010;

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

my $parser;
{
    # If we use the grammar module at the topmost scope, all other regexpes will not behave as expected
    use Regexp::Grammars;

    $parser = qr{
        (?: <tags>? )     # Main parser expression: to tag or not to tag

        <token: tags>
                (?:
                        <[MATCH=tag]>
                |
                        \(<[MATCH=tags]>\)
                )
                (?:
                        \+
                        (?:
                                <[MATCH=tag]>
                        |
                                \(<[MATCH=tags]>\)
                        )
                )*
        <token: tag>
                <name= ([\w\d\:]+) >  # Capture tag name, allowing namespaces
                <attributes>?
                <id>?
                <[class]>*
                <multiplicity>?
                <content>?
                (?: \> <children=tags>)?
        <token: class>                \. <MATCH=qn>
        <token: id>                   \# <MATCH=qn>
        <token: qn>                      <MATCH= ([\w\d\-\_\$]+)>
        <token: content>
                \=
                (?:
                        (?: \@ <param= ([_\w\d]+)> )
                |
                        <value=simplevalue>
                |
                        <value=quotedvalue>
                )
        <token: attributes>           
                \[
                <[MATCH=attribute]>
                (?: \s+ <[MATCH=attribute]> )*
                \]
        <token: attribute>
                <name=qn>
                (?:
                        =
                        (?:
                                <value=simplevalue>
                        |
                                <value=quotedvalue>
                        )
                )?
        <token: simplevalue>          [^"\s]+ 
        <rule: quotedvalue>           \" <MATCH= ([^"]+)> \"
        <token: multiplicity>         \* <MATCH= (\d+)>
                
    }x;
}


=head1 SYNOPSIS

This module expands expressions similar to those used by zen-coding to build up pieces of XML documents.

    use XML::ZCOL;

    my $foo = zcol_expand("div#page>div.logo+ul#navigation>li*5>a");

    or

    my $zcol = XML::ZCOL->new( formatter => "html", options => { indent => "\t" } );

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

An HTML generator, which inlines a few more elements than the more general html formatter.

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

Generate XML as a plain string. It does pretty much the same as the html formatter, but inlines elements only when they
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

=item zcol_expand( $template [, $formatter [, $options] ] )

Expand an template and return the resulting xml string.

The values for $formatter and $options will default to "html" and en empty hash respectively if they are not specified.

=cut
sub zcol_expand
{
    my $tpl = shift;
    my $formatter = shift // "html";
    my $formatter_options = shift // {};
    my $content = "";

    my $fh = __PACKAGE__->can("_recursive_parse_tree_$formatter")
        or die "Invalid formatter '$formatter' is not supported.";

    local %/ = ();
    $tpl =~ $parser;
    if( defined $/{tags} )
    {
        $content = &$fh($/{tags}, $formatter_options) if defined $/{tags};
        my $pph = __PACKAGE__->can("_post_process_$formatter");
        if( $pph ) 
        { $content = &$pph($content, $formatter_options); }
    }

    return $content;
}

=back

=cut




=head1 METHODS

=over

=cut

=item new( $formatter, $options )

Create a new zcol object

=cut
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $args = {@_};
    my $self = {
        formatter => $args->{formatter} // "html",
        options => $args->{options} // {},
    };

    bless($self, $class);
    return $self;
}

=item $zcol->expand( $template [, $formatter [, $options] ] )

Expand an template and return the resulting xml string.

You can optionally specify different formatter or options arguments for this expansion.

=cut
sub expand {
    my $self = shift;
    my $template = shift // "";
    my $formatter = shift // $self->{formatter};
    my $options = shift // $self->{options};

    return zcol_expand($template, $formatter, $options);
}

=back

=cut


#
## PRIVATE SUBS
#

# Private subroutine to replace numbering tokens
sub _parse_numbering {
    my $str = shift;
    my $num = shift;

    while($str =~ m/(\$+)/) {
        my $n = length($1);
        my $rep = sprintf("%0$n"."d",$num);
        $str =~ s#\${$n}#$rep#;
    }
    return $str;
}



##
## XML-ish standard formatter
##

sub _recursive_parse_tree_xml {
    my $elements = shift;
    my $options = shift;
    my $indent = shift // "";
    my $result = "";

    foreach my $el (@$elements) {
        #BUG: I do it this way because i did not find the way to get the grammar ok on distillation
        if(ref($el) eq "ARRAY")
        {
            $result .= _recursive_parse_tree_xml($el,$options,$indent);
            next;
        }

        foreach my $eln (1 .. ($el->{multiplicity} // 1) ) {

            # Start tag
            $result .= $indent . "<" . _parse_numbering($el->{name},$eln);

            # ID
            $result .= ' id="' . _parse_numbering($el->{id},$eln) . '"' if defined $el->{id};

            # Classes
            $result .= ' class="'.join(" ",map { _parse_numbering($_,$eln) } @{$el->{class}}).'"' if defined $el->{class};

            # Attributes
            if( defined $el->{attributes} )
            {
                $result .= " ".join(" ",
                    map {
                        _parse_numbering($_->{name}, $eln) . (
                            $_->{value} ?
                            '="' . _parse_numbering($_->{value}, $eln) . '"' : 
                            '="' . _parse_numbering($_->{name}, $eln) . '"'
                        )
                    } @{$el->{attributes}}
                );
            }

            # Tag delimiter
            $result .= ">";

            # Children nodes

            if($el->{children})
            { $result .= "\n"._recursive_parse_tree_xml( $el->{children}, $options, $indent . ($options->{indent} // "  ") ).$indent; }

            # Content
            if($el->{content}) {
                if($el->{content}{value}) {
                    $result .= $el->{content}{value};
                } elsif( $el->{content}{param} and defined $options->{params} and defined $options->{params}{$el->{content}{param}} ) {
                    my $param = $options->{params}{$el->{content}{param}};
                    given(ref($param)) {
                        when("CODE") { $result .= &$param(); }
                        when("ARRAY") { $result .= shift @$param; }
                        when("HASH") { $result .= $param->{_parse_numbering($el->{name},$eln)} // ""; }
                        default { $result .= $param; }
                    }
                }
            }

            # Close tag
            $result .= "</" . _parse_numbering($el->{name},$eln) . ">\n";
        }
    }

    return $result;
}
sub _post_process_xml {
    my $content = shift;
    my $options = shift // {};

    if($options->{xml_declaration})
    { $content = '<?xml version="1.0" encoding="'.($options->{xml_declaration_encoding} // "UTF-8") . "\">\n" . $content; }

    return $content;
}



##
## HTML-ish standard formatter
##

our @_HTML_INLINED = qw(li a p span td);

sub _recursive_parse_tree_html {
    my $elements = shift;
    my $options = shift;
    my $indent = shift // "";
    my $result = "";

    foreach my $el (@$elements) {
        #BUG: I do it this way because i did not find the way to get the grammar ok on distillation
        if(ref($el) eq "ARRAY")
        {
            $result .= _recursive_parse_tree_html($el,$options,$indent);
            next;
        }

        my $inlined = $el->{name} ~~ @_HTML_INLINED;

        foreach my $eln (1 .. ($el->{multiplicity} // 1) ) {

            # Start tag
            $result .= $indent . "<" . _parse_numbering($el->{name},$eln);

            # ID
            $result .= ' id="' . _parse_numbering($el->{id},$eln) . '"' if defined $el->{id};

            # Classes
            $result .= ' class="'.join(" ",map { _parse_numbering($_,$eln) } @{$el->{class}}).'"' if defined $el->{class};

            # Attributes
            if( defined $el->{attributes} )
            {
                $result .= " ".join(" ",
                    map {
                        _parse_numbering($_->{name}, $eln) . (
                            $_->{value} ?
                            '="' . _parse_numbering($_->{value}, $eln) . '"' : 
                            '="' . _parse_numbering($_->{name}, $eln) . '"'
                        )
                    } @{$el->{attributes}}
                );
            }

            # Tag delimiter
            $result .= ">";

            # Children nodes

            if($el->{children}) { 
                my $cres = "";
                
                if($inlined)
                {
                    $cres = _recursive_parse_tree_html( $el->{children}, $options, "" );
                    $cres =~ s/\n$//;
                }
                else
                {
                    $cres = "\n"._recursive_parse_tree_html( $el->{children}, $options, $indent . ($options->{indent} // "  ") );
                    $cres .= $indent;
                }

                $result .= $cres;
            }

            # Content
            if($el->{content}) {
                if($el->{content}{value}) {
                    $result .= $el->{content}{value};
                } elsif( $el->{content}{param} and defined $options->{params} and defined $options->{params}{$el->{content}{param}} ) {
                    my $param = $options->{params}{$el->{content}{param}};
                    given(ref($param)) {
                        when("CODE") { $result .= &$param(); }
                        when("ARRAY") { $result .= shift @$param; }
                        when("HASH") { $result .= $param->{_parse_numbering($el->{name},$eln)} // ""; }
                        default { $result .= $param; }
                    }
                }
            }

            # Close tag
            $result .= "</" . _parse_numbering($el->{name},$eln) . ">\n";
        }
    }

    return $result;
}
sub _post_process_html {
    my $content = shift;
    my $options = shift // {};

    if($options->{fullwrap}) {
        my $title = $options->{head_title} // "Some title";
        $content = <<EOH;
<html>
<head>
 <title>$title</title>
</head>

<body>
$content
</body>
</html>
EOH
    }

    return _post_process_xml($content, $options);
}


##
## RAW formatter for debugging purposes
## 
sub _recursive_parse_tree_raw {
    return shift;
}

=head1 DEBUGGING

This module disabled debugging due to a strange "Out of memory" bug that appeared on some forking scenarios. This behaviour could not be isolated into a testcase by now, so any patches or scripts to reproduce this bug will be highly appreciated.

To enable debugging, see Regexp::Grammars section on debugging.

Making a long story short, you can add this to the top of the grammar:
    <logfile: gram_log >
    <debug: on>

=cut

=head1 TODO

=over

=item Implement classfull formatters

This module could be greatly improved by using classfull xml/html generation through any of the many XML libraries available on CPAN, as well as by using Conway's Regexp::Grammars ability to generate classfull trees at parse-time.

By now, and to keep dependences to the minimum, it generates raw string data instead.

=item Abstract formatters on a separate class

This will be the first major step towards publication on CPAN. Formatter API should be clearly defined and abstracted into a pluggable class (e.g: through Module::Pluggable or via module registration hooks).

Once this is done, a much saner design of the nearly-the-same html and xml string formatters will be possible

=item Enhance grammar to support parameters on attributes

This should not be complicated, since it is already mostly the same. Special attention should be paid to delimiter effect there.

=item Enhance test suite

A must for CPAN publication to make good use of tester's reports.

=item Documentation

Docs should be extended to cover new formatter creation (delayed until they are abstracted into isolated classes). Better examples must also be provided: include paramater usage and more complex templates.

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

=item The grammar should be modified to correctly support distillation on grouping. On the first quick group implementation, the required changes made groups after a simple tag delete it from the stack. The current solution generates a children array which may have nested arrays (instead of hashes only), and a trick is done on formatters to get that specific case ok.

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
