use strict;
use warnings;
use Test::More tests => 4;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_db';
use MySchema;

new_db();

my $form = HTML::FormFu->new;

$form->load_config_file('t/deprecated-save_to_model/opt_accessor.yml');

my $schema = MySchema->connect('dbi:SQLite:dbname=t/test.db');

my $master = $schema->resultset('Master')->create({ id => 1 });

# filler rows
{
    # user 1
    my $u1 = $master->create_related( 'user', {
        name => 'mr. bar',
    } );
}

# rows we're going to use
{
    # user 2
    my $u2 = $master->create_related( 'user', {
        name => 'mr. foo',
    } );
}

{
    $form->process( {
        id       => 2,
        fullname => 'mr billy bob',
    } );
    
    my $row = $schema->resultset('User')->find(2);

    {
        my $warnings;
        local $SIG{ __WARN__ } = sub { $warnings++ };

        $form->save_to_model($row);
        ok( $warnings, 'warning thrown' );
    }
}

{
    my $row = $schema->resultset('User')->find(2);

    is( $row->title,    'mr' );
    is( $row->name,     'billy bob' );
    is( $row->fullname, 'mr billy bob' );
}

