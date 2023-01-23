use strict;
use warnings;

use Test2::V0;

use FindBin qw( $RealBin );
use lib "$FindBin::RealBin/../../../../src";
use cloud::azure::custom::api;


my ($self) = @_;

require centreon::plugins::options;
$self->{options} = centreon::plugins::options->new();
require centreon::plugins::output;
$self->{output} = centreon::plugins::output->new(options => $self->{options});

$self->{options}->{resource_location} = 'resource_location';
$self->{options}->{resource_type} = 'resource_type';

my $api = cloud::azure::custom::api->new(options => $self->{options}, output => $self->{output});

$api->{management_endpoint} = 'https://management.azure.com';
$api->{subscription} = '00000000-0000-0000-0000-000000000001';
$api->{api_version} = '2019-10-01';



#################
# Policy States #
#################

my $urlPolicyStates = $api->azure_set_url(
    providers => 'Microsoft.PolicyInsights/policyStates',
    resource => 'default',
    resource_group => 'myResourceGroup',
    query_name => 'queryResults',
    query => '$select=ResourceType, ResourceLocation, ResourceGroup, PolicyDefinitionName, ComplianceState'
);
is($urlPolicyStates, 'https://management.azure.com/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/myResourceGroup/providers/Microsoft.PolicyInsights/policyStates/default/queryResults?api-version=2019-10-01&$select=ResourceType, ResourceLocation, ResourceGroup, PolicyDefinitionName, ComplianceState');

$urlPolicyStates = $api->azure_set_url(
    providers => 'Microsoft.PolicyInsights/policyStates',
    resource => 'default',
    query_name => 'queryResults',
    query => '$select=ResourceType, ResourceLocation, ResourceGroup, PolicyDefinitionName, ComplianceState'
);
is($urlPolicyStates, 'https://management.azure.com/subscriptions/00000000-0000-0000-0000-000000000001/providers/Microsoft.PolicyInsights/policyStates/default/queryResults?api-version=2019-10-01&$select=ResourceType, ResourceLocation, ResourceGroup, PolicyDefinitionName, ComplianceState');

$urlPolicyStates = $api->azure_set_url(
    providers => 'Microsoft.PolicyInsights/policyStates',
    resource => 'default',
    query_name => 'queryResults',
    force_api_version => '2018-01-01',
    query => '$select=ResourceType, ResourceLocation, ResourceGroup, PolicyDefinitionName, ComplianceState'
);
is($urlPolicyStates, 'https://management.azure.com/subscriptions/00000000-0000-0000-0000-000000000001/providers/Microsoft.PolicyInsights/policyStates/default/queryResults?api-version=2018-01-01&$select=ResourceType, ResourceLocation, ResourceGroup, PolicyDefinitionName, ComplianceState');



#####################
# Sql Elastic Pools #
#####################

my $urlSqlServers = $api->azure_set_url(
    query_name => 'elasticPools'
);
my $urlsqlelasticpools = $api->azure_list_sqlelasticpools_set_url();
is($urlSqlServers, $urlsqlelasticpools);

$urlSqlServers = $api->azure_set_url(
    resource_group => 'myResourceGroup',
    query_name => 'elasticPools',
);
$urlsqlelasticpools = $api->azure_list_sqlelasticpools_set_url(
    resource_group => 'myResourceGroup'
);
is($urlSqlServers, $urlsqlelasticpools);

$urlSqlServers = $api->azure_set_url(
    providers => 'Microsoft.Sql/servers',
    resource => 'myServer',
    query_name => 'elasticPools',
);
$urlsqlelasticpools = $api->azure_list_sqlelasticpools_set_url(
    server => 'myServer'
);
is($urlSqlServers, $urlsqlelasticpools);

$urlSqlServers = $api->azure_set_url(
    query_name => 'elasticPools',
    force_api_version => '2018-01-01'
);
$urlsqlelasticpools = $api->azure_list_sqlelasticpools_set_url(
    force_api_version => '2018-01-01'
);
is($urlSqlServers, $urlsqlelasticpools);

$urlSqlServers = $api->azure_set_url(
    providers => 'Microsoft.Sql/servers',
    resource => 'myServer',
    resource_group => 'myResourceGroup',
    query_name => 'elasticPools',
    force_api_version => '2021-11-01'
);
$urlsqlelasticpools = $api->azure_list_sqlelasticpools_set_url(
    resource_group => 'myResourceGroup',
    server => 'myServer',
    force_api_version => '2021-11-01'
);
is($urlSqlServers, $urlsqlelasticpools);

done_testing;