#!/perl

use strict;
use warnings;

use Test::Most;
use Test::SchemaMock;

BEGIN {
    use_ok 'Test::SchemaMock';
};


isa_ok my $schema_mock = Test::SchemaMock->new(), 'Test::SchemaMock';
isa_ok my $schema = $schema_mock->schema, 'Test::Schema';

done_testing;
