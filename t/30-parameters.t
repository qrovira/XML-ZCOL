#!perl -T

use 5.010;

use warnings;
use strict;

#Autoflush
$| = 1;

use Test::More tests => 5;
use Data::Dumper;
use XML::ZCOL;

my $params = {};


sub dump_res($) {
    my $res = shift;

    say "Result: ";
    say $res;
}

cmp_ok( zcol_expand('tag=@param1',"XML",{params => $params}), "eq", <<EOTR, "Tag content parameter - missing");
<tag></tag>
EOTR

$params->{param1} = "test parameter";
cmp_ok( zcol_expand('tag=@param1',"XML",{params => $params}), "eq", <<EOTR, "Tag content parameter - string");
<tag>test parameter</tag>
EOTR

$params->{param1} = ['one','two','three'];
cmp_ok( zcol_expand('tag*3=@param1',"XML",{params => $params}), "eq", <<EOTR, "Tag content parameter - array");
<tag>one</tag>
<tag>two</tag>
<tag>three</tag>
EOTR

$params->{param1} = { a => "click here", span => "Link Title" };
cmp_ok( zcol_expand('span=@param1+a=@param1',"XML",{params => $params}), "eq", <<EOTR, "Tag content parameter - hash");
<span>Link Title</span>
<a>click here</a>
EOTR

$params->{param1} = sub { return "This is a bit of text inserted from within a callback" };
cmp_ok( zcol_expand('span=@param1',"XML",{params => $params}), "eq", <<EOTR, "Tag content parameter - callback");
<span>This is a bit of text inserted from within a callback</span>
EOTR



