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
            json_string => '[  {     "datastore":  "datastore-14",     "name":  "Datastore - Systeme",     "type":  "VMFS",     "free_space": 610635087872,     "capacity": 799937658880  }]',
            expected_object => [ { 'name' => 'Datastore - Systeme', 'capacity' => '799937658880', 'datastore' => 'datastore-14', 'free_space' => '610635087872', 'type' => 'VMFS' } ],
            booleans_as_strings => 0,
            msg    => 'Objects without booleans'
        },
        {
            json_string => '[  {    "datastore": "datastore-14",    "name": "Datastore - Systeme",    "type": "VMFS",    "free_space": 610635087872,    "capacity": 799937658880  },  {    "datastore": "datastore-25",    "name": "Datastore - ESX02",    "type": "VMFS",    "free_space": 340472627200,    "capacity": 341986770944  },  {    "datastore": "datastore-31",    "name": "Datastore - ESX03",    "type": "VMFS",    "free_space": 340472627200,    "capacity": 341986770944  },  {    "datastore": "datastore-38",    "name": "Datastore - Developpement 15000",    "type": "VMFS",    "free_space": 5586639912960,    "capacity": 7794560335872  },  {    "datastore": "datastore-39",    "name": "Datastore - Developpement 7200",    "type": "VMFS",    "free_space": 5422671986688,    "capacity": 5516885491712  },  {    "datastore": "datastore-40",    "name": "Datastore - ESX01",    "type": "VMFS",    "free_space": 340472627200,    "capacity": 341986770944  },  {    "datastore": "datastore-45",    "name": "Datastore - Developpement",    "type": "VMFS",    "free_space": 4376304287744,    "capacity": 7499818205184  },  {    "datastore": "datastore-46",    "name": "Datastore - Production",    "type": "VMFS",    "free_space": 615292862464,    "capacity": 1299764477952  }]',
            expected_object => [ { 'name' => 'Datastore - Systeme', 'capacity' => '799937658880', 'datastore' => 'datastore-14', 'free_space' => '610635087872', 'type' => 'VMFS' }, { 'free_space' => '340472627200', 'type' => 'VMFS', 'name' => 'Datastore - ESX02', 'capacity' => '341986770944', 'datastore' => 'datastore-25' }, { 'name' => 'Datastore - ESX03', 'capacity' => '341986770944', 'datastore' => 'datastore-31', 'free_space' => '340472627200', 'type' => 'VMFS' }, { 'free_space' => '5586639912960', 'type' => 'VMFS', 'name' => 'Datastore - Developpement 15000', 'capacity' => '7794560335872', 'datastore' => 'datastore-38' }, { 'capacity' => '5516885491712', 'name' => 'Datastore - Developpement 7200', 'datastore' => 'datastore-39', 'type' => 'VMFS', 'free_space' => '5422671986688' }, { 'capacity' => '341986770944', 'name' => 'Datastore - ESX01', 'datastore' => 'datastore-40', 'type' => 'VMFS', 'free_space' => '340472627200' }, { 'datastore' => 'datastore-45', 'capacity' => '7499818205184', 'name' => 'Datastore - Developpement', 'free_space' => '4376304287744', 'type' => 'VMFS' }, { 'capacity' => '1299764477952', 'name' => 'Datastore - Production', 'datastore' => 'datastore-46', 'free_space' => '615292862464', 'type' => 'VMFS' } ],
            booleans_as_strings => 1,
            msg    => 'Objects without booleans'
        },
        {
            json_string => '{    "accessible": false,    "multiple_host_access": true,    "name":  "Datastore - Developpement 7200",    "type":  "VMFS",    "free_space": 5422671986688,    "thin_provisioning_supported": true }  ',
            expected_object => { 'multiple_host_access' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ), 'thin_provisioning_supported' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ), 'name' => 'Datastore - Developpement 7200', 'free_space' => '5422671986688', 'type' => 'VMFS', 'accessible' => bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' ) },
            booleans_as_strings => 0,
            msg    => 'Object with booleans as booleans'
        },
        {
            json_string => '{    "accessible": false,    "multiple_host_access": true,    "name":  "Datastore - Developpement 7200",    "type":  "VMFS",    "free_space": 5422671986688,    "thin_provisioning_supported": true }  ',
            expected_object => { 'multiple_host_access' => 'true', 'thin_provisioning_supported' => 'true', 'name' => 'Datastore - Developpement 7200', 'free_space' => '5422671986688', 'type' => 'VMFS', 'accessible' => 'false' },
            booleans_as_strings => 1,
            msg    => 'Object with booleans as strings'
        },
        {
            json_string => '{    "accessible": false,    "multiple_host_access": true,    "name":  "Trick: true, we\'re still in the string  Developpement 7200",    "type":  "VMFS",    "free_space": 5422671986688,    "thin_provisioning_supported": true }  ',
            expected_object => { 'multiple_host_access' => 'true', 'thin_provisioning_supported' => 'true', 'name' => 'Trick: true, we\'re still in the string  Developpement 7200', 'free_space' => '5422671986688', 'type' => 'VMFS', 'accessible' => 'false' },
            booleans_as_strings => 1,
            msg    => 'Object with tricky booleans as strings'
        },
        {
            json_string => '{    "accessible": false,    "multiple_host_access": true,    "name":  ": true, we\'re still in the string  Developpement 7200",    "type":  "VMFS",    "free_space": 5422671986688,    "thin_provisioning_supported": true }  ',
            expected_object => { 'multiple_host_access' => 'true', 'thin_provisioning_supported' => 'true', 'name' => ': true, we\'re still in the string  Developpement 7200', 'free_space' => '5422671986688', 'type' => 'VMFS', 'accessible' => 'false' },
            booleans_as_strings => 1,
            msg    => 'Object with more tricky booleans as strings'
        }
    );
    for my $test (@tests) {
        my ($object, $exit_code) = centreon::plugins::misc::json_decode($test->{json_string}, booleans_as_strings => $test->{booleans_as_strings});
        is($object, $test->{expected_object}, $test->{msg});

    }

}

test();
done_testing();

