use Test::More no_plan => 1;

use strict;
use warnings;

BEGIN {
      use_ok('Splunk::Conf');
}

my $splunk = new_ok( 'Splunk::Conf' => [
    url => 'https://localhost:8089/services',
]);

is( $splunk->url, 'https://localhost:8089/services', '... url got initialized' );

my $user = $ENV{SPLUNK_USER} || 'admin';
my $pass = $ENV{SPLUNK_PASS} || 'changeme';

my $skey = $splunk->login( $user, $pass );

like( $skey, qr/\w+/, '... logged in');
is( $key, $splunk, '... key stored properly');

#$splunk->stanza_remove( 'inputs', 'monitor:///hello/world' );
$splunk->stanza_create( 'inputs', 'monitor:///hello/world' );

$splunk->stanza_attrib_update( 'inputs', 'monitor:///hello/world',
                                     disabled => 'false',
                                     host_segment => 3,
                                     sourcetype => 'syslog' );

$splunk->stanza_attrib_kv( 'inputs', 'monitor:///hello/world' );

$splunk->list();
$splunk->list( 'inputs' );
$splunk->list( 'inputs', 'monitor:///hello/world' );
