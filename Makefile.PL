use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'XML::ZCOL',
    AUTHOR              => q{Quim Rovira <<qrovira@ebdsoft.com>>},
    VERSION_FROM        => 'lib/XML/ZCOL.pm',
    ABSTRACT_FROM       => 'lib/XML/ZCOL.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    EXE_FILES           => [ 'bin/zcol' ],
    PREREQ_PM => {
        'Test::More' => 0,
        'Regexp::Grammars' => 0,
        'Module::Pluggable' => '4.0',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'XML-ZCOL-*' },
);
