package XML::ZCOL::Parser::HTML;

use warnings;
use strict;
use 5.010;

use base 'XML::ZCOL::Parser';

sub grammar {
    # If we use the grammar module at the topmost scope, all other regexpes will not behave as expected
    use Regexp::Grammars;

    return qr{
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
        <token: simplevalue>          [\w\$]+ 
        <rule: quotedvalue>           \" <MATCH= ([^"]+)> \"
        <token: multiplicity>         \* <MATCH= (\d+)>
                
    }x;
}


our %_HTML_INLINED = map { $_ => 1 } qw(li a p span td);

sub parse_tree_node {
    my ($self, $node, $count, $depth) = @_;
    my $result = "";

    # Start tag
    $result .= "<" . $self->parse_numbering($node->{name},$count);

    # ID
    $result .= ' id="' . $self->parse_numbering($node->{id},$count) . '"' if defined $node->{id};

    # Classes
    $result .= ' class="'.join(" ",map { $self->parse_numbering($_,$count) } @{$node->{class}}).'"' if defined $node->{class};

    # Attributes
    if( defined $node->{attributes} )
    {
        $result .= " ".join(" ",
            map {
                $self->parse_numbering($_->{name}, $count) . (
                    $_->{value} ?
                    '="' . $self->parse_numbering($_->{value}, $count) . '"' : 
                    '="' . $self->parse_numbering($_->{name}, $count) . '"'
                )
            } @{$node->{attributes}}
        );
    }

    # Tag delimiter
    $result .= ">";

    # Children nodes
    if( $node->{children} ) {
        if( $_HTML_INLINED{ $node->{name} } ) {
            $result .= $self->parse_tree_node_list( $node->{children}, undef );
        } else {
            $result =
                $self->indent( $result, $depth ).
                $self->parse_tree_node_list( $node->{children}, defined($depth) ? $depth + 1 : undef );
        }
    }

    # Content
    $result .= $self->parse_node_content( $node, $count )
        if($node->{content});

    # Close tag
    if( $node->{children} && !$_HTML_INLINED{ $node->{name} } ) {
        $result .= $self->indent("</" . $self->parse_numbering($node->{name},$count) . ">", $depth);
    } else {
        $result .= "</" . $self->parse_numbering($node->{name},$count) . ">";
        $result = $self->indent( $result, $depth );
    }

    return $result;
}

# Final post-processing (for wrapping and common parts)
sub post_process {
    my $self = shift;
    my $content = shift;

    if($self->{fullwrap}) {
        my $title = $self->{head_title} // "Some title";
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

    return $content;
}


1;
