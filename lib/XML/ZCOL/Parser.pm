package XML::ZCOL::Parser;

use warnings;
use strict;
use 5.010;


sub new {
    my ($proto, %args) = @_;
    my $self = { %args };
    bless $self, ref($proto) || $proto;
    return $self;
}

sub parse_tree {
    my ($self, $tree) = @_;

    return $self->post_process(
        $self->parse_tree_node_list( $tree->{tags}, 0 )
    );
}

sub parse_tree_node_list {
    my ($self, $nodes, $depth) = @_;
    my @queue = @$nodes;
    my $result = "";

    while( my $el = shift @queue ) {
        # Handle grouping sub-arrays
        if(ref($el) eq "ARRAY")
        {
            unshift @queue, @$el;
            next;
        }

        $result .= $self->parse_tree_node($el, $_, $depth) foreach( 1 .. ($el->{multiplicity} // 1) );
    }

    return $result;
}

sub parse_tree_node { die "Abstract parse_node called"; }

# Final post-processing (for wrapping and common parts)
sub post_process {
    my $self = shift;
    my $content = shift;

    return $content;
}

# Handle indentation
sub indent {
    my ($self, $result, $depth) = @_;

    return $result unless defined $depth;

    return ( ($self->{indent} // "  ") x $depth ).$result."\n";
}

# Replace "$" tokens with the right numbering, zero-padded
sub parse_numbering {
    my ($self, $string, $count) = @_;

    while($string =~ m/(\$+)/) {
        my $n = length($1);
        my $rep = sprintf("%0$n"."d",$count);
        $string =~ s#\${$n}#$rep#;
    }
    return $string;
}

sub parse_node_content {
    my ($self, $node, $count) = @_;
    my $content = "";

    if($node->{content}{value}) {
        $content = $node->{content}{value};
    }
    # undocumented feature for content generators
    elsif( $node->{content}{param} and defined $self->{params} and defined $self->{params}{$node->{content}{param}} ) {
        my $param = $self->{params}{$node->{content}{param}};
        given(ref($param)) {
            when("CODE") { $content = &$param(); }
            when("ARRAY") { $content = shift @$param; }
            when("HASH") { $content = $param->{$self->parse_numbering($node->{name},$count)} // ""; }
            default { $content = $param; }
        }
    }

    return $content;
}


1;
