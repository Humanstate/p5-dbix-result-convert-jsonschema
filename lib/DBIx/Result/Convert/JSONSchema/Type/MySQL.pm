package DBIx::Result::Convert::JSONSchema::Type::MySQL;

use strict;
use warnings;

our $VERSION = '0.01';

use Readonly;


=head1 SYNOPSUS

Defines mapping between DBIx result field types and JSON schema field types

    use DBIx::Result::Convert::JSONSchema::Type::MySQL;
    my $type_map = DBIx::Result::Convert::JSONSchema::Type::MySQL->get_type_map;

=cut


Readonly my %TYPE_MAP => (
    string  => [
        qw/ char varchar binary varbinary blob text mediumtext tinytext /,
        qw/ date datetime timestamp time year /
    ],
    enum    => [ qw/ enum set / ],
    integer => [ qw/ integer smallint tinyint mediumint bigint bit / ],
    number  => [ qw/ decimal float double /, 'double precision' ],
    object  => [ qw/ json / ],
);

=head2 C<get_type_map>

Return mapping of DBIx::Class:Result field name => JSON Schema field name

    # { decimal => 'number', time => 'string', ... }
    my $map = DBIx::Result::Convert::Type::MySQL::get_type_map();

=cut

sub get_type_map {
    my ( $class ) = @_;

    my $mapped_fields;
    foreach my $json_type ( keys %TYPE_MAP ) {
        foreach my $dbix_type ( @{ $TYPE_MAP{ $json_type } } ) {
            $mapped_fields->{ $dbix_type } = $json_type;
        }
    }

    return $mapped_fields;
}

1;
