package DBIx::Result::Convert::JSONSchema::Default::MySQL;

use strict;
use warnings;

our $VERSION = '0.01';

use Readonly;


=head1 SYNOPSIS

Defines length types and default field maximum/minimum values based on database field type

    use DBIx::Result::Convert::JSONSchema::Default::MySQL;
    my $length_map = DBIx::Result::Convert::JSONSchema::Default::MySQL->get_length_map;
    my $length_type_map = DBIx::Result::Convert::JSONSchema::Default::MySQL->get_length_type_map;

=cut


Readonly my %LENGTH_TYPE_MAP => (
    string  => [ qw/ minLength maxLength / ],
    number  => [ qw/ minimum maximum / ],
    integer => [ qw/ minimum maximum / ],
);

Readonly my %LENGTH_MAP => (
    char       => [ 0, 1 ],
    varchar    => [ 0, 255 ],
    binary     => [ 0, 255 ],
    varbinary  => [ 0, 255 ],
    blob       => [ 0, 65_535 ],
    text       => [ 0, 65_535 ],
    mediumtext => [ 0, 16_777_215 ],
    tinytext   => [ 0, 255 ],
    date       => [ 10, 10 ],
    datetime   => [ 19, 19 ],
    timestamp  => [ 26, 26 ],
    time       => [ 8, 8 ],
    year       => [ 4, 4 ],
    integer    => {
        signed   => [ -2_147_483_648, 2_147_483_647 ],
        unsigned => [ 0,              4_294_967_295 ],
    },
    smallint   => {
        signed   => [ -32_768, 32_767 ],
        unsigned => [ 0,       65_535 ],
    },
    tinyint    => {
        signed   => [ -128, 127 ],
        unsigned => [ 0,    255 ],
    },
    mediumint  => {
        signed   => [ -8_388_608, 8_388_607  ],
        unsigned => [ 0,          16_777_215 ],
    },
    bigint     => {
        signed   => [ (2**63) * -1, (2**63) - 1 ],
        unsigned => [ 0,            (2**64) - 1 ],
    },
    bit        => {
        signed   => [ 0, 1 ],
        unsigned => [ 0, 1 ],
    },
);

sub get_length_map      { \%LENGTH_MAP }
sub get_length_type_map { \%LENGTH_TYPE_MAP }

1;
