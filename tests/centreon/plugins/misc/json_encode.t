use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{is like match};
use FindBin;
use lib "$FindBin::RealBin/../../../../src";
use centreon::plugins::misc;
use centreon::plugins::output;
use centreon::plugins::options;

sub test {
    my $mock_output = mock 'centreon::plugins::output'; # this is from Test2::Tools::Mock, included by Test2::V0

    my $option = centreon::plugins::options->new();
    my $output = centreon::plugins::output->new(options => $option);

    my @tests = (
        {
            object      => [ { 'name' => 'Datastore - Systeme', 'capacity' => '799937658880', 'datastore' => 'datastore-14', 'free_space' => '610635087872', 'type' => 'VMFS' } ],
            json_string => '[{"capacity":"799937658880","datastore":"datastore-14","free_space":"610635087872","name":"Datastore - Systeme","type":"VMFS"}]',
            msg         => 'Object to JSON'
        },
        {
            object => [ { 'name' => 'Datastore - Systeme', 'capacity' => '799937658880', 'datastore' => 'datastore-14', 'free_space' => '610635087872', 'type' => 'VMFS' }, { 'free_space' => '340472627200', 'type' => 'VMFS', 'name' => 'Datastore - ESX02', 'capacity' => '341986770944', 'datastore' => 'datastore-25' }, { 'name' => 'Datastore - ESX03', 'capacity' => '341986770944', 'datastore' => 'datastore-31', 'free_space' => '340472627200', 'type' => 'VMFS' }, { 'free_space' => '5586639912960', 'type' => 'VMFS', 'name' => 'Datastore - Developpement 15000', 'capacity' => '7794560335872', 'datastore' => 'datastore-38' }, { 'capacity' => '5516885491712', 'name' => 'Datastore - Developpement 7200', 'datastore' => 'datastore-39', 'type' => 'VMFS', 'free_space' => '5422671986688' }, { 'capacity' => '341986770944', 'name' => 'Datastore - ESX01', 'datastore' => 'datastore-40', 'type' => 'VMFS', 'free_space' => '340472627200' }, { 'datastore' => 'datastore-45', 'capacity' => 7499818205184, 'name' => 'Datastore - Developpement', 'free_space' => 4376304287744, 'type' => 'VMFS' }, { 'capacity' => 1299764477952, 'name' => 'Datastore - Production', 'datastore' => 'datastore-46', 'free_space' => 615292862464, 'type' => 'VMFS' } ],
            json_string => '[{"capacity":"799937658880","datastore":"datastore-14","free_space":"610635087872","name":"Datastore - Systeme","type":"VMFS"},{"capacity":"341986770944","datastore":"datastore-25","free_space":"340472627200","name":"Datastore - ESX02","type":"VMFS"},{"capacity":"341986770944","datastore":"datastore-31","free_space":"340472627200","name":"Datastore - ESX03","type":"VMFS"},{"capacity":"7794560335872","datastore":"datastore-38","free_space":"5586639912960","name":"Datastore - Developpement 15000","type":"VMFS"},{"capacity":"5516885491712","datastore":"datastore-39","free_space":"5422671986688","name":"Datastore - Developpement 7200","type":"VMFS"},{"capacity":"341986770944","datastore":"datastore-40","free_space":"340472627200","name":"Datastore - ESX01","type":"VMFS"},{"capacity":7499818205184,"datastore":"datastore-45","free_space":4376304287744,"name":"Datastore - Developpement","type":"VMFS"},{"capacity":1299764477952,"datastore":"datastore-46","free_space":615292862464,"name":"Datastore - Production","type":"VMFS"}]',
            msg    => 'Objects table to JSON'
        },
        {
            object => { 'multiple_host_access' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ), 'thin_provisioning_supported' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ), 'name' => 'Datastore - Developpement 7200', 'free_space' => '5422671986688', 'type' => 'VMFS', 'accessible' => bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' ) },
            json_string => '{"accessible":false,"free_space":"5422671986688","multiple_host_access":true,"name":"Datastore - Developpement 7200","thin_provisioning_supported":true,"type":"VMFS"}',
            msg    => 'Object to JSON with booleans as Booleans'
        },
        {
            object => { 'multiple_host_access' => 'true', 'thin_provisioning_supported' => 'true', 'name' => 'Datastore - Developpement 7200', 'free_space' => '5422671986688', 'type' => 'VMFS', 'accessible' => 'false' },
            json_string => '{"accessible":"false","free_space":"5422671986688","multiple_host_access":"true","name":"Datastore - Developpement 7200","thin_provisioning_supported":"true","type":"VMFS"}',
            msg    => 'Object to JSON with booleans as strings'
        },
        {
            object => { 'multiple_host_access' => 'true', 'thin_provisioning_supported' => 'true', 'name' => 'Trick: true, we\'re still in the string  Developpement 7200', 'free_space' => 5422671986688, "capacity" => 799937658880, 'type' => 'VMFS', 'accessible' => 'false' },
            json_string => '{"accessible":"false","capacity":799937658880,"free_space":5422671986688,"multiple_host_access":"true","name":"Trick: true, we\'re still in the string  Developpement 7200","thin_provisioning_supported":"true","type":"VMFS"}',
            msg    => 'Object to JSON with integers'
        },
        {
            object => { 'multiple_host_access' => 'true', 'thin_provisioning_supported' => 'true', 'name' => ': true, we\'re still in the string  Developpement 7200 => ok', 'free_space' => '5422671986688', 'type' => 'VMFS', 'accessible' => 'false' },
            json_string => '{"accessible":"false","free_space":"5422671986688","multiple_host_access":"true","name":": true, we\'re still in the string  Developpement 7200 => ok","thin_provisioning_supported":"true","type":"VMFS"}',
            msg    => 'Object to JSON with tricky string'
        }
    );

    for my $test (@tests) {
        my ($json_string, $exit_code) = centreon::plugins::misc::json_encode($test->{object}, booleans_as_strings => $test->{booleans_as_strings});
        print "$json_string\n";
        is($json_string, $test->{json_string}, $test->{msg});
    }

    ok(1, "pass");
}

test();
done_testing();
