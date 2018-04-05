#!/perl

use strict;
use warnings;

use Test::Most;

BEGIN {
    use_ok('DBIx::Result::Convert::JSONSchema');
};


throws_ok {
    DBIx::Result::Convert::JSONSchema->new();
} qr/missing required argument schema/;

throws_ok {
    DBIx::Result::Convert::JSONSchema->new( schema => 1 );
} qr/missing required argument schema_source/;

throws_ok {
    DBIx::Result::Convert::JSONSchema->new( schema => 1, schema_source => 'Dog' );
} qr/given schema_source 'Dog' is not valid/;

isa_ok
    my $converter = DBIx::Result::Convert::JSONSchema->new( schema => 1, schema_source => 'MySQL' ),
    'DBIx::Result::Convert::JSONSchema';

done_testing;
