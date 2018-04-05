use 5.024003;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'DBIx::Result::Convert::JSONSchema',
    VERSION_FROM  => 'lib/DBIx/Result/Convert/JSONSchema.pm',
    PREREQ_PM     => {},
    ABSTRACT_FROM => 'lib/DBIx/Result/Convert/JSONSchema.pm',
    AUTHOR        => 'V Skrupskis <valters.skrupskis@gmail.com>',
    LICENSE       => 'perl',
);
