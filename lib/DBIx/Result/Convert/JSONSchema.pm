package DBIx::Result::Convert::JSONSchema;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp;
use Module::Load qw/ load /;
use Readonly;


=head1 SYNOPSIS

Convert DBIx::Class:Result::X schema to JSON schema.
NOTE: Conversion does not include relationships between the tables. It simply
takes DBIx Result class and tries it's best to produce JSON schema equivalent.

    use DBIx::Result::Convert::JSONSchema;

    my $converter = DBIx::Result::Convert::JSONSchema->new(
        schema        => DBIx::Class::Schema,  # required
        schema_source => 'MySQL',              # required
    );

    my $json_schema = $converter->get_json_schema('MySchemaResult');
    ...

=cut


Readonly my %ALLOWED_SCHEMA_SOURCE => map { $_ => 1 } qw/ MySQL /;
Readonly my %PATTERN_MAP           => (
    date      => '^\d{4}-\d{2}-\d{2}$',
    time      => '^\d{2}:\d{2}:\d{2}$',
    year      => '^\d{4}$',
    datetime  => '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$',
    timestamp => '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$',
);

=head2 C<new>

Constructs a new instance of DBIx::Result::Convert::JSONSchema and returns it.
Additional arguments can be provided to overwrite initial state of field conversion types.

    my $converter = DBIx::Result::Convert::JSONSchema->new(
        schema          => DBIx::Class::Schema,                               # required
        schema_source   => 'MySQL',                                           # required
        type_map        => { integer => [ qw/ integer / ], ... },             # optional
        length_map      => { char    => [ 0, 1 ], ... },                      # optional
        length_type_map => { string  => [ qw/ minLength maxLength / ], ... }, # optional
        pattern_map     => { date    => '^\d{4}-\d{2}-\d{2}$' },              # optional
    );

    ARGS:
        Required:
            schema:
                Instance of DBIx::Class::Schema
            schema_source:
                One of database sources from which the result sets were generated e.g. 'MySQL'
        Optional:
            type_map:
                Mapping between DBIx data_type field and JSON schema data type (see L<DBIx::Result::Convert::JSONSchema::Type::MySQL>)
            length_map:
                Min/max value definition of DBIx result fields (see L<DBIx::Result::Convert::JSONSchema::Default::MySQL>)
            length_type_map:
                Min/max DBIx field type to JSON schema field type limit key (see L<DBIx::Result::Convert::JSONSchema::Default::MySQL>)
            pattern_map:
                JSON schema patterns based on DBIx result field type (see C<%PATTERN_MAP>)

=cut

sub new {
    my ( $class, %args ) = @_;

    croak 'missing required argument schema'        unless $args{schema};
    croak 'missing required argument schema_source' unless $args{schema_source};

    croak sprintf(
        q{given schema_source '%s' is not valid, allowed types - %s},
        $args{schema_source}, join ', ', keys %ALLOWED_SCHEMA_SOURCE
    )
        unless $ALLOWED_SCHEMA_SOURCE{ $args{schema_source} };

    my $type_class     = $class . '::Type::'    . $args{schema_source};
    my $defaults_class = $class . '::Default::' . $args{schema_source};

    load $type_class;
    load $defaults_class;

    $args{type_map} = {
        %{ $type_class->get_type_map() },
        %{ $args{type_map} || {} },
    };
    $args{length_map} = {
        %{ $defaults_class->get_length_map() },
        %{ $args{length_map} || {} },
    };
    $args{length_type_map} = {
        %{ $defaults_class->get_length_type_map() },
        %{ $args{length_type_map} || {} },
    };
    $args{pattern_map} = {
        %PATTERN_MAP,
        %{ $args{pattern_map} || {} }
    };

    my $self = \%args;
    bless $self, $class;

    return $self;
}

=head2 C<schema_source>

Return or set the schema source from which the defaults were loaded.

    my $schema_source = $self->schema_source('MySQL');
    my $schema_source = $self->schema_source; # 'MySQL'

=cut

sub schema_source {
    my ( $self, $schema_source ) = @_;

    if ( $schema_source ) {
        $self->{schema_source} = $schema_source;
    }

    return $self->{schema_source}
}

=head2 C<schema>

Return or set instance of DBIx::Class::Schema.

    my $schema = $self->schema(DBIx::Class::Schema);
    my $schema = $self->schema; # Instance of DBIx::Class::Schema

=cut

sub schema {
    my ( $self, $schema ) = @_;

    if ( $schema ) {
        $self->{schema} = $schema;
    }

    return $self->{schema}
}

=head2 C<type_map>

Return or set type map of DBIx types to JSON schema types.
See L<DBIx::Result::Convert::JSONSchema::Type::MySQL>

    my $type_map = $self->type_map({ integer => [ qw/ integer / ], ... });
    my $type_map = $self->type_map; # { integer => [ qw/ integer / ], ... }

=cut

sub type_map {
    my ( $self, $type_map ) = @_;

    if ( $type_map ) {
        $self->{type_map} = $type_map;
    }

    return $self->{type_map};
}

=head2 C<length_type_map>

Return or set type length map between DBIx types and JSON types.
See L<DBIx::Result::Convert::JSONSchema::Default::MySQL>

    my $length_type_map = $self->length_type_map({ string => [ qw/ minLength maxLength / ], ... });
    my $length_type_map = $self->length_type_map; # { string => [ qw/ minLength maxLength / ], ... }

=cut

sub length_type_map {
    my ( $self, $length_type_map ) = @_;

    if ( $length_type_map ) {
        $self->{length_type_map} = $length_type_map;
    }

    return $self->{length_type_map};
}

=head2 C<length_map>

Return or set length map which defines min/max values for schema fields.
See L<DBIx::Result::Convert::JSONSchema::Default::MySQL>

    my $length_map = $self->length_map({ char => [ 0, 1 ], ... });
    my $length_map = $self->length_map; # { char => [ 0, 1 ], ... }

=cut

sub length_map {
    my ( $self, $length_map ) = @_;

    if ( $length_map ) {
        $self->{length_map} = $length_map;
    }

    return $self->{length_map};
}

=head2 C<pattern_map>

Return or set JSON schema patterns based on DBIx field types.
See C<%PATTERN_MAP>

    my $pattern_map = $self->pattern_map({ date => '^\d{4}-\d{2}-\d{2}$', ... });
    my $pattern_map = $self->pattern_map; # { date => '^\d{4}-\d{2}-\d{2}$', ... }

=cut

sub pattern_map {
    my ( $self, $pattern_map ) = @_;

    if ( $pattern_map ) {
        $self->{pattern_map} = $pattern_map;
    }

    return $self->{pattern_map};
}

=head2 C<get_json_schema>

Returns somewhat equivalent JSON schema based on DBIx result source name.

    my $json_schema = $converted->get_json_schema( 'TableSource', {
        decimals_to_pattern             => 1,
        has_schema_property_description => 1,
        allow_additional_properties     => 0,
        overwrite_schema_property_keys  => {
            name    => 'cat',
            address => 'dog',
        },
        overwrite_schema_properties     => {
            name => {
                minimum => 10,
                maximum => 20,
                type    => 'number',
            },
        },
        exclude_required   => [ qw/ name address / ],
        exclude_properties => [ qw/ mouse house / ],
    });

    ARGS:
        Required ARGS[0]:
            - Source name e.g. 'Address'
        Optional ARGS[1]:
            decimals_to_pattern:
                True/false value to indicate if 'number' type field should be converted to 'string' type with
                RegExp pattern based on decimal place definition in database
            has_schema_property_description:
                True/false value to indicate if basic JSON schema properties should include 'description' key
                containing basic information about field
            allow_additional_properties:
                1/0 to indicate if JSON schema should accept properties which are not defined by default
            overwrite_schema_property_keys:
                HashRef containing { OLD_PROPERTY => NEW_PROPERTY } to overwrite default column names, default
                property attributes from old key will be assigned to new key
                (!) The key conversion is executed last, every other option e.g. exclude_properties will work
                only on original database column names
            overwrite_schema_properties:
                HashRef of { PROPERTY_NAME => { ... JSON SCHEMA ATTRIBUTES ... } } which will replace default generated
                schema properties.
            exclude_required:
                ArrayRef of database column names which should always be excluded from required schema properties
            exclude_properties:
                ArrayRef of database column names which should be excluded from JSON schema

=cut

sub get_json_schema {
    my ( $self, $source, $args ) = @_;
    $args //= {};

    croak 'missing schema source' unless $source;

    # additional schema generation options
    my $decimals_to_pattern             = delete $args->{decimals_to_pattern};
    my $has_schema_property_description = delete $args->{has_schema_property_description};
    my $allow_additional_properties     = delete $args->{allow_additional_properties}    // 0;
    my $overwrite_schema_property_keys  = delete $args->{overwrite_schema_property_keys} // {};
    my $overwrite_schema_properties     = delete $args->{overwrite_schema_properties}    // {};
    my %exclude_required                = map { $_ => 1 } @{ delete $args->{exclude_required}   || [] };
    my %exclude_properties              = map { $_ => 1 } @{ delete $args->{exclude_properties} || [] };

    my %json_schema = (
        type                  => 'object',
        additional_properties => $allow_additional_properties,
        required              => [],
        properties            => {},
    );

    my $source_info = $self->_get_column_info($source);

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

        # DBIx schema size constraint -> JSON schema size constraint
        if ( $self->length_map->{ $column_info->{data_type} } ) {
            $self->_set_json_schema_property_range( \%json_schema, $column_info, $column );
        }

        # DBIx schema required -> JSON schema required
        if ( ! $source_info->{ $column }->{default_value} && ! $source_info->{ $column }->{is_nullable} && ! $exclude_required{ $column } ) {
            push @{ $json_schema{required} }, $column;
        }

        # DBIx schema defaults -> JSON schema defaults (no refs e.g. current_timestamp)
        if ( $source_info->{ $column }->{default_value} && ! ref $source_info->{ $column }->{default_value} ) {
            $json_schema{properties}->{ $column }->{default} = $source_info->{ $column }->{default_value};
        }

        # DBIx schema list -> JSON enum list
        if ( $json_type eq 'enum' && $column_info->{extra} && $column_info->{extra}->{list} ) { # no autovivification
            $json_schema{properties}->{ $column }->{enum} = $column_info->{extra}->{list};
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
            my $property_description = $self->_get_json_schema_property_description( $column, $json_schema{properties}->{ $column } );
            $json_schema{properties}->{ $column }->{description} = $property_description;
        }

        # Overwrites: merge JSON schema property key values with custom ones
        if ( my $merge_property = delete $overwrite_schema_properties->{ $column } ) {
            $json_schema{properties}->{ $column } = {
                %{ $json_schema{properties}->{ $column } },
                %{ $merge_property },
            };
        }

        # Overwrite: replace JSON schema keys
        if ( my $new_key = $overwrite_schema_property_keys->{ $column } ) {
            $json_schema{properties}->{ $new_key } = delete $json_schema{properties}->{ $column };
        }
    }

    return \%json_schema;
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

    my $is_numeric = $property->{type} =~ /^integer|number$/;

    my $description = $is_numeric ? 'Numeric' : ucfirst $property->{type};
    $description .= sprintf ' type value for field %s', $column;

    # non-decimal numeric type
    if ( $property->{type} eq 'integer' && $property->{maximum} ) {
        my $integer_example = $property->{default} || int rand $property->{maximum};
        $description .= ' e.g. ' . $integer_example;
    }
    elsif ( $property->{type} eq 'string' && $property->{pattern} ) {
        $description .= sprintf ' with pattern %s ', $property->{pattern};
    }

    return $description;
}

# Convert from DBIx field length to JSON schema field length based on field type
sub _set_json_schema_property_range {
    my ( $self, $json_schema, $column_info, $column ) = @_;

    my $json_schema_min_type = $self->length_type_map->{ $self->type_map->{ $column_info->{data_type} } }->[0];
    my $json_schema_max_type = $self->length_type_map->{ $self->type_map->{ $column_info->{data_type} } }->[1];

    my $json_schema_min = $self->_get_json_schema_property_min_max_value( $column_info, 0 );
    my $json_schema_max = $self->_get_json_schema_property_min_max_value( $column_info, 1 );

    # bump min value to 0 (don't see how this starts from negative)
    $json_schema_min = 0 if $column_info->{is_auto_increment};

    $json_schema->{properties}->{ $column }->{ $json_schema_min_type } = $json_schema_min;
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

1;
