#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'DBIx::Result::Convert::JSONSchema',
    ABSTRACT_FROM => 'lib/DBIx/Result/Convert/JSONSchema.pm',
    VERSION_FROM  => 'lib/DBIx/Result/Convert/JSONSchema.pm',
    AUTHOR        => 'Valters Skrupskis <valters.skrupskis@humanstate.com>',
    LICENSE       => 'perl',
    PREREQ_PM     => {
        'Moo'             => '2.003004',
        'Types::Standard' => '1.002001',
        'Carp'            => '1.40',
        'Module::Load'    => '0.32',
        'Readonly'        => '2.05',
        'FindBin'         => '1.51',
    },
    BUILD_REQUIRES => {
        'Test::Most'          => 0,
        'DBIx::Class::Schema' => 0,
        'DBD::Mock'           => '1.45',
        'DBI'                 => '1.641',
    },
    META_MERGE => {
        requires => {
            perl => '5.010001',
        },
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            homepage   => 'https://metacpan.org/module/DBIx::Result::Convert::JSONSchema',
            bugtracker => 'https://github.com/Humanstate/p5-dbix-result-convert-jsonschema/issues',
            repository => 'https://github.com/Humanstate/p5-dbix-result-convert-jsonschema',
        },
    },
    test => {
        RECURSIVE_TEST_FILES => 1,
    },
);

# vim: ts=4:sw=4:et
