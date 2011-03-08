package XML::ZCOL::Generator;

use warnings;
use strict;
use 5.010;

=head1 NAME

XML::ZCOL::Generator - XML::ZCOL base generator class

=head1 SYNOPSIS

This is the base class for generator modules that take the resulting parse tree from XML::ZCOL and
transform it to some other arbitrary data structure, ranging from an xml/html string to nested
objects.

=cut

=head1 METHODS

=over

=cut

=head2 

=cut

sub  {}

##
## PRIVATE methods
##

# This method does the recursion on the tree, calling the appropiate generator method on each node
sub _recursive_parse_tree {
    my $self = shift;
    my $elements = shift;
    my @nodes;

    foreach my $el (@$elements) {
        #BUG: I do it this way because i did not find the way to get the grammar ok on distillation
        if(ref($el) eq "ARRAY")
        {
            push @nodes, $self->_recursive_parse_tree($el);
            next;
        }

        foreach my $eln (1 .. ($el->{multiplicity} // 1) ) {
            my ($node,@nodechilds);

            # Children nodes
            if($el->{children})
            { @nodechilds = $self->_recursive_parse_tree_xml( $el->{children} ); }

            # Before node generation, we should parse the attributes, id, class, and content, to replace
            # both numbering and also paramters

            $node = $self->generate_node($el, \@nodechilds);


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

1; # End of XML::ZCOL::Generator
