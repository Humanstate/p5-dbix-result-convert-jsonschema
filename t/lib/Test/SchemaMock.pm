package Test::SchemaMock;

use strict;
use warnings;

use DBD::Mock;
use DBI;
use Test::Schema;


sub new {
    my ( $class, %args ) = @_;

    my $self = \%args;
    bless $self, $class;

    return $self;
}

sub schema {
    my ( $self, $schema ) = @_;

    if ( $schema ) {
        $self->{schema} = $schema;
    }
    elsif ( ! $self->{schema} ) {
        $self->{schema} = Test::Schema->connect( sub { $self->dbh } );
    }

    return $self->{schema};
}

sub dbh {
    my ( $self, $dbh ) = @_;

    if ( $dbh ) {
        $self->{dbh} = $dbh;
    }
    elsif ( ! $self->{dbh} ) {
        my $dbh = DBI->connect( 'DBI:Mock:', '', '' )
            or die "Cannot create handle: $DBI::errstr\n";
        $self->{dbh} = $dbh;
    }

    return $self->{dbh};
}

sub mock_data {
    return {
        timestamp => {
            minLength => 26,
            type => 'string',
            pattern => '^\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}$',
            maxLength => 26,
        },
        char => {
            type => 'string',
            maxLength => 1,
            minLength => 0,
        },
        bit => {
            maximum => 1,
            minimum => 0,
            type => 'integer',
        },
        int => {
            maximum => 2147483647,
            minimum => '-2147483648',
            type => 'integer',
        },
        text => {
            minLength => 0,
            type => 'string',
            maxLength => 65535,
        },
        smallint => {
            maximum => 32767,
            type => 'integer',
            minimum => -32768,
        },
        decimal => {
            type => 'number',
        },
        time => {
            minLength => 8,
            maxLength => 8,
            type => 'string',
            pattern => '^\\d{2}:\\d{2}:\\d{2}$',
        },
        tinyint => {
            minimum => -128,
            type => 'integer',
            maximum => 127,
        },
        varbinary => {
            maxLength => 255,
            type => 'string',
            minLength => 0,
        },
        datetime => {
            minLength => 19,
            maxLength => 19,
            type => 'string',
            pattern => '^\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}$',
        },
        bigint => {
            type => 'integer',
            minimum => '-9.22337203685478e+18',
            maximum => '9.22337203685478e+18',
        },
        year => {
            minLength => 4,
            maxLength => 4,
            pattern => '^\\d{4}$',
            type => 'string',
        },
        json => {
            type => 'object',
        },
        tinytext => {
            maxLength => 255,
            type => 'string',
            minLength => 0,
        },
        float => {
            type => 'number',
        },
        mediumtext => {
            minLength => 0,
            type => 'string',
            maxLength => 16777215,
        },
        enum => {
            type => 'enum',
            enum => [
                'X',
                'Y',
                'Z',
            ],
        },
        date => {
            minLength => 10,
            maxLength => 10,
            pattern => '^\\d{4}-\\d{2}-\\d{2}$',
            type => 'string',
        },
        integer => {
            maximum => 2147483647,
            minimum => '-2147483648',
            type => 'integer',
        },
        binary => {
            type => 'string',
            maxLength => 1,
            minLength => 0,
        },
        set => {
            enum => [
                'X',
                'Y',
                'Z',
            ],
            type => 'enum',
        },
        varchar => {
            maxLength => 255,
            type => 'string',
            minLength => 0,
        },
        blob => {
            minLength => 0,
            maxLength => 65535,
            type => 'string',
        },
        longtext => {
            maxLength => 16777215,
            type => 'string',
            minLength => 0,
        },
        double => {
            type => 'number',
        },
        numeric => {
            type => 'number',
        },
        mediumint => {
            minimum => -8388608,
            type => 'integer',
            maximum => 8388607,
        },
    };
}

1;
