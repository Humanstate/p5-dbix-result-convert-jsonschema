package DBIx::Result::Convert::JSONSchema;

our $VERSION = '0.06';


=head1 NAME

DBIx::Result::Convert::JSONSchema - Convert DBIx result schema to JSON schema

=begin html

    <a href='https://travis-ci.org/Humanstate/p5-dbix-result-convert-jsonschema?branch=master'><img src='https://travis-ci.org/Humanstate/p5-dbix-result-convert-jsonschema.svg?branch=master' alt='Build Status' /></a>
    <a href='https://coveralls.io/github/Humanstate/p5-dbix-result-convert-jsonschema?branch=master'><img src='https://coveralls.io/repos/github/Humanstate/p5-dbix-result-convert-jsonschema/badge.svg?branch=master' alt='Coverage Status' /></a>

=end html

=head1 VERSION

    0.06

=head1 SYNOPSIS

    use DBIx::Result::Convert::JSONSchema;

    my $SchemaConvert = DBIx::Result::Convert::JSONSchema->new( schema => Schema );
    my $json_schema = $SchemaConvert->get_json_schema( DBIx::Class::ResultSource );

=head1 DESCRIPTION

This module attempts basic conversion of L<DBIx::Class::ResultSource> to equivalent
of L<http://json-schema.org/>.
By default the conversion assumes that the L<DBIx::Class::ResultSource> originated
from MySQL database. Thus all the types and defaults are set based on MySQL
field definitions.
It is, however, possible to overwrite field type map and length map to support
L<DBIx::Class::ResultSource> from other database solutions.

Note, relations between tables are not taken in account!

=cut


use Moo;
use Types::Standard qw/ InstanceOf Enum HashRef /;

use Carp;
use Module::Load qw/ load /;


has schema => (
    is       => 'ro',
    isa      => InstanceOf['DBIx::Class::Schema'],
    required => 1,
);

has schema_source => (
    is      => 'lazy',
    isa     => Enum[ qw/ MySQL / ],
    default => 'MySQL',
);

has length_type_map => (
    is      => 'rw',
    isa     => HashRef,
    default => sub {
        return {
            string  => [ qw/ minLength maxLength / ],
            number  => [ qw/ minimum maximum / ],
            integer => [ qw/ minimum maximum / ],
        };
    },
);

has type_map => (
    is      => 'rw',
    isa     => HashRef,
    default => sub {
        my ( $self ) = @_;

        my $type_class = __PACKAGE__ . '::Type::' . $self->schema_source;
        load $type_class;

        return $type_class->get_type_map;
    },
);

has length_map => (
    is      => 'rw',
    isa     => HashRef,
    default => sub {
        my ( $self ) = @_;

        my $defaults_class = __PACKAGE__ . '::Default::' . $self->schema_source;
        load $defaults_class;

        return $defaults_class->get_length_map;
    },
);

has pattern_map => (
    is      => 'rw',
    isa     => HashRef,
    lazy    => 1,
    default  => sub {
        return {
            time      => '^\d{2}:\d{2}:\d{2}$',
            year      => '^\d{4}$',
            datetime  => '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$',
            timestamp => '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$',
        };
    }
);

has format_map => (
    is      => 'rw',
    isa     => HashRef,
    lazy    => 1,
    default  => sub {
        return {
            date => 'date',
        };
    }
);


=head2 get_json_schema

Returns somewhat equivalent JSON schema based on DBIx result source name.

    my $json_schema = $converted->get_json_schema( 'TableSource', {
        schema_declaration              => 'http://json-schema.org/draft-04/schema#',
        decimals_to_pattern             => 1,
        has_schema_property_description => 1,
        allow_additional_properties     => 0,
        ignore_property_defaults        => 1,
        overwrite_schema_property_keys  => {
            name    => 'cat',
            address => 'dog',
        },
        add_schema_properties           => {
            address => { ... },
            bank_account => '#/definitions/bank_account',
        },
        overwrite_schema_properties     => {
            name => {
                _action  => 'merge', # one of - merge/overwrite
                minimum  => 10,
                maximum  => 20,
                type     => 'number',
            },
        },
        include_required   => [ qw/ street city / ],
        exclude_required   => [ qw/ name address / ],
        exclude_properties => [ qw/ mouse house / ],

        dependencies => {
            first_name => [ qw/ middle_name last_name / ],
        },
    });

Optional arguments to change how JSON schema is generated:

=over 8

=item * schema_declaration

Declare which version of the JSON Schema standard that the schema was written against.

L<https://json-schema.org/understanding-json-schema/reference/schema.html>

B<Default>: "http://json-schema.org/schema#"

=item * decimals_to_pattern

1/0 - value to indicate if 'number' type field should be converted to 'string' type with
RegExp pattern based on decimal place definition in database.

B<Default>: 0

=item * has_schema_property_description

Generate schema description for fields e.g. 'Optional numeric type value for field context e.g. 1'.

B<Default>: 0

=item * ignore_property_defaults

Do not set schema B<default> property field based on default in DBIx schema

B<Default>: 0

=item * allow_additional_properties

Define if the schema accepts additional keys in given payload.

B<Default>: 0

=item * add_property_minimum_value

If field does not have format type add minimum values for number and string types based on DB field type.
This might not make sense in most cases as the minimum is either 0 or the lower bound if number is signed.

B<Default>: 0

=item * overwrite_schema_property_keys

HashRef representing mapping between old property name and new property name to overwrite existing schema keys,
Properties from old key will be assigned to the new property.

B<Note> The key conversion is executed last, every other option e.g. C<exclude_properties> will work only on original
database column names.

=item * overwrite_schema_properties

HashRef of property name and new attributes which can be either overwritten or merged based on given B<_action> key.

=item * exclude_required

ArrayRef of database column names which should always be EXCLUDED from REQUIRED schema properties.

=item * include_required

ArrayRef of database column names which should always be INCLUDED in REQUIRED schema properties

=item * exclude_properties

ArrayRef of database column names which should be excluded from JSON schema AT ALL

=item * dependencies

L<https://json-schema.org/understanding-json-schema/reference/object.html#property-dependencies>

=item * add_schema_properties

HashRef of custom schema properties that must be included in final definition
Note that custom properties will overwrite defaults

=item * schema_overwrite

HashRef of top level schema properties e.g. 'required', 'properties' etc. to overwrite

=back

=cut

sub get_json_schema {
    my ( $self, $source, $args ) = @_;

    croak 'missing schema source' unless $source;

    $args //= {};

    # additional schema generation options
    my $decimals_to_pattern             = $args->{decimals_to_pattern};
    my $has_schema_property_description = $args->{has_schema_property_description};
    my $ignore_property_defaults        = $args->{ignore_property_defaults};
    my $overwrite_schema_property_keys  = $args->{overwrite_schema_property_keys} // {};
    my $add_schema_properties           = $args->{add_schema_properties};
    my $overwrite_schema_properties     = $args->{overwrite_schema_properties} // {};
    my $add_property_minimum_value      = $args->{add_property_minimum_value};
    my %exclude_required                = map { $_ => 1 } @{ $args->{exclude_required} || [] };
    my %include_required                = map { $_ => 1 } @{ $args->{include_required} || [] };
    my %exclude_properties              = map { $_ => 1 } @{ $args->{exclude_properties} || [] };

    my $dependencies                = $args->{dependencies};
    my $schema_declaration          = $args->{schema_declaration} // 'http://json-schema.org/schema#';
    my $allow_additional_properties = $args->{allow_additional_properties} // 0;
    my $schema_overwrite            = $args->{schema_overwrite} // {};

    my %json_schema = (
        '$schema'            => $schema_declaration,
        type                 => 'object',
        required             => [],
        properties           => {},
        additionalProperties => $allow_additional_properties,

        ( $dependencies ? ( dependencies => $dependencies ) : () ),
    );

    my $source_info = $self->_get_column_info( $source );

    SCHEMA_COLUMN:
    foreach my $column ( keys %{ $source_info } ) {
        next SCHEMA_COLUMN if $exclude_properties{ $column };

        my $column_info = $source_info->{ $column };

        # DBIx schema data type -> JSON schema data type
        my $json_type = $self->type_map->{ $column_info->{data_type} }
            or croak sprintf(
                'unknown data type - %s (source: %s, column: %s)',
                $column_info->{data_type}, $source, $column
            );

        $json_schema{properties}->{ $column }->{type} = $json_type;

        # DBIx schema type -> JSON format
        my $format_type = $self->format_map->{ $column_info->{data_type} };
        if ( $format_type ) {
            $json_schema{properties}->{ $column }->{format} = $format_type;
        }

        # DBIx schema size constraint -> JSON schema size constraint
        if ( ! $format_type && $self->length_map->{ $column_info->{data_type} } ) {
            $self->_set_json_schema_property_range( \%json_schema, $column_info, $column, $add_property_minimum_value );
        }

        # DBIx schema required -> JSON schema required
        my $is_required_field = $include_required{ $column };
        if ( $is_required_field || ( ! $column_info->{default_value} && ! $column_info->{is_nullable} && ! $exclude_required{ $column } ) ) {
            my $required_property = $overwrite_schema_property_keys->{ $column } // $column;
            push @{ $json_schema{required} }, $required_property;
        }

        # DBIx schema defaults -> JSON schema defaults (no refs e.g. current_timestamp)
        if ( ! $ignore_property_defaults && defined $column_info->{default_value} && ! ref $column_info->{default_value} ) {
            $json_schema{properties}->{ $column }->{default} = $column_info->{default_value};
        }

        # DBIx schema list -> JSON enum list
        if ( $json_type eq 'enum' && $column_info->{extra} && $column_info->{extra}->{list} ) { # no autovivification
            $json_schema{properties}->{ $column }->{enum} = $column_info->{extra}->{list};
        }

        # Consider 'is nullable' to accept 'null' values in all cases where field is not explicitly required
        if ( ! $is_required_field && $column_info->{is_nullable} ) {
            if ( $json_type eq 'enum' ) {
                $json_schema{properties}->{ $column }->{enum} //= [];
                push @{ $json_schema{properties}->{ $column }->{enum} }, 'null';
            }
            else {
                $json_schema{properties}->{ $column }->{type} = [ $json_type, 'null' ];
            }
        }

        # DBIx decimal numbers -> JSON schema numeric string pattern
        if ( $json_type eq 'number' && $decimals_to_pattern ) {
            if ( $column_info->{size} && ref $column_info->{size} eq 'ARRAY' ) {
                $json_schema{properties}->{ $column }->{type}    = 'string';
                $json_schema{properties}->{ $column }->{pattern} = $self->_get_decimal_pattern( $column_info->{size} );
            }
        }

        # JSON schema field patterns
        if ( $self->pattern_map->{ $column_info->{data_type} } ) {
            $json_schema{properties}->{ $column }->{pattern} = $self->pattern_map->{ $column_info->{data_type} };
        }

        # JSON schema property description
        if ( ! $json_schema{properties}->{ $column }->{description} && $has_schema_property_description ) {
            my $property_description = $self->_get_json_schema_property_description(
                $overwrite_schema_property_keys->{ $column } // $column,
                $json_schema{properties}->{ $column }
            );
            $json_schema{properties}->{ $column }->{description} = $property_description;
        }

        # JSON schema custom additional properties
        if ( $add_schema_properties ) {
            foreach my $property_key ( keys %{ $add_schema_properties } ) {
                $json_schema{properties}->{ $property_key } = $add_schema_properties->{ $property_key };
            }
        }

        # Overwrites: merge JSON schema property key values with custom ones
        if ( my $overwrite_property = delete $overwrite_schema_properties->{ $column } ) {
            my $action = delete $overwrite_property->{_action} // 'merge';

            $json_schema{properties}->{ $column } = {
                %{ $action eq 'merge' ? $json_schema{properties}->{ $column } : {} },
                %{ $overwrite_property }
            };
        }

        # Overwrite: replace JSON schema keys
        if ( my $new_key = $overwrite_schema_property_keys->{ $column } ) {
            $json_schema{properties}->{ $new_key } = delete $json_schema{properties}->{ $column };
        }
    }

    return {
        %json_schema,
        %{ $schema_overwrite },
    };
}

# Return DBIx result source column info for the given result class name
sub _get_column_info {
    my ( $self, $source ) = @_;

    return $self->schema->source($source)->columns_info;
}

# Returns RegExp pattern for decimal numbers based on database field definition
sub _get_decimal_pattern {
    my ( $self, $size ) = @_;

    my ( $x, $y ) = @{ $size };
    return sprintf '^\d{1,%s}\.\d{0,%s}$', $x - $y, $y;
}

# Generates somewhat logical field description based on type and length constraints
sub _get_json_schema_property_description {
    my ( $self, $column, $property ) = @_;

    if ( ! $property->{type} ) {
        if ( $property->{enum} ) {
            return sprintf 'Enum list type, one of - %s', join( ', ', @{ $property->{enum} } );
        }

        return '';
    }

    return '' if $property->{type} eq 'object'; # no idea how to handle

    my %types;
    if ( ref $property->{type} eq 'ARRAY' ) {
        %types = map { $_ => 1 } @{ $property->{type} };
    }
    else {
        $types{ $property->{type} } = 1;
    }

    my $description = '';
    $description   .= 'Optional' if $types{null};

    my $type_part;
    if ( grep { /^integer|number$/ } keys %types ) {
        $type_part = 'numeric';
    }
    else {
        ( $type_part ) = grep { $_ ne 'null' } keys %types; # lucky roll, last type that isn't 'null' should be legit
    }

    $description .= $description ? " $type_part" : ucfirst $type_part;
    $description .= sprintf ' type value for field %s', $column;

    if ( ( grep { /^integer$/ } keys %types ) && $property->{maximum} ) {
        my $integer_example = $property->{default} // int rand $property->{maximum};
        $description       .= ' e.g. ' . $integer_example;
    }
    elsif ( ( grep { /^string$/ } keys %types ) && $property->{pattern} ) {
        $description .= sprintf ' with pattern %s ', $property->{pattern};
    }

    return $description;
}

# Convert from DBIx field length to JSON schema field length based on field type
sub _set_json_schema_property_range {
    my ( $self, $json_schema, $column_info, $column, $add_property_minimum_value ) = @_;

    my $json_schema_min_type = $self->length_type_map->{ $self->type_map->{ $column_info->{data_type} } }->[0];
    my $json_schema_max_type = $self->length_type_map->{ $self->type_map->{ $column_info->{data_type} } }->[1];

    my $json_schema_min = $self->_get_json_schema_property_min_max_value( $column_info, 0 );
    my $json_schema_max = $self->_get_json_schema_property_min_max_value( $column_info, 1 );

    # bump min value to 1 (don't see how this starts from negative)
    $json_schema_min = 1 if $column_info->{is_auto_increment};

    $json_schema->{properties}->{ $column }->{ $json_schema_min_type } = $json_schema_min
        if $add_property_minimum_value;
    $json_schema->{properties}->{ $column }->{ $json_schema_max_type } = $json_schema_max;

    if ( $column_info->{size} ) {
        $json_schema->{properties}->{ $column }->{ $json_schema_max_type } = $column_info->{size};
    }

    return;
}

# Returns min/max value from DBIx result field definition or lookup from defaults
sub _get_json_schema_property_min_max_value {
    my ( $self, $column_info, $range ) = @_;

    if ( $column_info->{extra} && $column_info->{extra}->{unsigned} ) { # no autovivification
        return $self->length_map->{ $column_info->{data_type} }->{unsigned}->[ $range ];
    }

    return ref $self->length_map->{ $column_info->{data_type} } eq 'ARRAY' ? $self->length_map->{ $column_info->{data_type} }->[ $range ]
        : $self->length_map->{ $column_info->{data_type} }->{signed}->[ $range ];
}

=head1 SEE ALSO

L<DBIx::Class::ResultSource> - Result source object

=head1 AUTHOR

malishew - C<malishew@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation
or file a bug report then please raise an issue / pull request:

    https://github.com/Humanstate/p5-dbix-result-convert-jsonschema

=cut

__PACKAGE__->meta->make_immutable;
