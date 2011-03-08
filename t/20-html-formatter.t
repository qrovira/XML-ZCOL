#!perl -T

use 5.010;

use warnings;
use strict;

#Autoflush
$| = 1;

use Test::More tests => 17;
use Data::Dumper;
use XML::ZCOL;



sub dump_res($) {
    my $res = shift;

    say "Result: ";
    say $res;
}

# Create a zcol instance: option-less xml formatter
my $zcol = XML::ZCOL->new( formatter => "html" );

cmp_ok( $zcol->expand('lonelytag'), "eq", <<EOTR, "Lonely tag");
<lonelytag></lonelytag>
EOTR

cmp_ok( $zcol->expand('tag1+tag2'), "eq", <<EOTR, "Two same-lavel tags");
<tag1></tag1>
<tag2></tag2>
EOTR

cmp_ok( $zcol->expand('namespace:lonelytag'), "eq", <<EOTR, "Namespaced tag");
<namespace:lonelytag></namespace:lonelytag>
EOTR

cmp_ok( $zcol->expand('classfulltag.myclass'), "eq", <<EOTR, "Tag with class");
<classfulltag class="myclass"></classfulltag>
EOTR

cmp_ok( $zcol->expand('identifiabletag#myid'), "eq", <<EOTR, "Tag with id");
<identifiabletag id="myid"></identifiabletag>
EOTR

cmp_ok( $zcol->expand('div#page>div.logo+ul#navigation>li*5>a'), "eq", <<EOTR, "tags, ids, same levels and nesting");
<div id="page">
  <div class="logo"></div>
  <ul id="navigation">
    <li><a></a></li>
    <li><a></a></li>
    <li><a></a></li>
    <li><a></a></li>
    <li><a></a></li>
  </ul>
</div>
EOTR

cmp_ok( $zcol->expand('div#page>div.logo+ul#navigation>li.class$$$*5>a'), "eq", <<EOTR, "same again, with numberred classes");
<div id="page">
  <div class="logo"></div>
  <ul id="navigation">
    <li class="class001"><a></a></li>
    <li class="class002"><a></a></li>
    <li class="class003"><a></a></li>
    <li class="class004"><a></a></li>
    <li class="class005"><a></a></li>
  </ul>
</div>
EOTR

cmp_ok( $zcol->expand('div[att1=smurf]'), "eq", <<EOTR, "tag with custom attribute, simple");
<div att1="smurf"></div>
EOTR

cmp_ok( $zcol->expand('div[att1=smurf att2]'), "eq", <<EOTR, "tag with custom attribute, value-less");
<div att1="smurf" att2="att2"></div>
EOTR

cmp_ok( $zcol->expand('div[att1=smurf att2 att3="Some random text here"]'), "eq", <<EOTR, "tag with custom attribute, quoted");
<div att1="smurf" att2="att2" att3="Some random text here"></div>
EOTR

cmp_ok( $zcol->expand('div[att1=smurf att2 att3="Some random text] here"]'), "eq", <<EOTR, "tag with custom attribute, nasty quoted");
<div att1="smurf" att2="att2" att3="Some random text] here"></div>
EOTR

cmp_ok( $zcol->expand('tag=plainstring'), "eq", <<EOTR, "Tag content - unquoted");
<tag>plainstring</tag>
EOTR

cmp_ok( $zcol->expand('tag="plain string"'), "eq", <<EOTR, "Tag content - quoted");
<tag>plain string</tag>
EOTR


# Enable XML declaration and check
$zcol->{options}{xml_declaration} = 1;
cmp_ok( $zcol->expand("div"), "eq", <<EOTR, "Default XML declaration" );
<?xml version="1.0" encoding="UTF-8">
<div></div>
EOTR

# Different encoding
# Enable XML declaration and check
$zcol->{options}{xml_declaration_encoding} = "ISO-8859-1";
cmp_ok( $zcol->expand("div"), "eq", <<EOTR, "XML declaration with some other encoding" );
<?xml version="1.0" encoding="ISO-8859-1">
<div></div>
EOTR



# full wrapping
$zcol->{options}{fullwrap} = 1;
cmp_ok( $zcol->expand("div"), "eq", <<EOTR, "HTML wrapping" );
<?xml version="1.0" encoding="ISO-8859-1">
<html>
<head>
 <title>Some title</title>
</head>

<body>
<div></div>

</body>
</html>
EOTR


$zcol->{options}{head_title} = "My spam";
cmp_ok( $zcol->expand("div"), "eq", <<EOTR, "HTML wrapping - custom title" );
<?xml version="1.0" encoding="ISO-8859-1">
<html>
<head>
 <title>My spam</title>
</head>

<body>
<div></div>

</body>
</html>
EOTR


