package Paws::EC2 {
  use Moose;
  sub service { 'ec2' }
  sub version { '2015-04-15' }
  sub flattened_arrays { 1 }

  with 'Paws::API::Caller', 'Paws::API::RegionalEndpointCaller', 'Paws::Net::V4Signature', 'Paws::Net::EC2Caller', 'Paws::Net::XMLResponse';

  
  sub AcceptVpcPeeringConnection {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::AcceptVpcPeeringConnection', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AllocateAddress {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::AllocateAddress', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AssignPrivateIpAddresses {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::AssignPrivateIpAddresses', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AssociateAddress {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::AssociateAddress', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AssociateDhcpOptions {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::AssociateDhcpOptions', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AssociateRouteTable {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::AssociateRouteTable', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AttachClassicLinkVpc {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::AttachClassicLinkVpc', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AttachInternetGateway {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::AttachInternetGateway', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AttachNetworkInterface {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::AttachNetworkInterface', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AttachVolume {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::AttachVolume', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AttachVpnGateway {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::AttachVpnGateway', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AuthorizeSecurityGroupEgress {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::AuthorizeSecurityGroupEgress', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AuthorizeSecurityGroupIngress {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::AuthorizeSecurityGroupIngress', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub BundleInstance {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::BundleInstance', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CancelBundleTask {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CancelBundleTask', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CancelConversionTask {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CancelConversionTask', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CancelExportTask {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CancelExportTask', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CancelImportTask {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CancelImportTask', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CancelReservedInstancesListing {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CancelReservedInstancesListing', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CancelSpotFleetRequests {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CancelSpotFleetRequests', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CancelSpotInstanceRequests {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CancelSpotInstanceRequests', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ConfirmProductInstance {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::ConfirmProductInstance', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CopyImage {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CopyImage', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CopySnapshot {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CopySnapshot', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateCustomerGateway {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CreateCustomerGateway', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateDhcpOptions {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CreateDhcpOptions', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateFlowLogs {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CreateFlowLogs', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateImage {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CreateImage', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateInstanceExportTask {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CreateInstanceExportTask', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateInternetGateway {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CreateInternetGateway', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateKeyPair {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CreateKeyPair', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateNetworkAcl {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CreateNetworkAcl', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateNetworkAclEntry {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CreateNetworkAclEntry', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateNetworkInterface {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CreateNetworkInterface', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreatePlacementGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CreatePlacementGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateReservedInstancesListing {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CreateReservedInstancesListing', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateRoute {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CreateRoute', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateRouteTable {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CreateRouteTable', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateSecurityGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CreateSecurityGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateSnapshot {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CreateSnapshot', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateSpotDatafeedSubscription {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CreateSpotDatafeedSubscription', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateSubnet {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CreateSubnet', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateTags {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CreateTags', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateVolume {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CreateVolume', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateVpc {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CreateVpc', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateVpcEndpoint {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CreateVpcEndpoint', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateVpcPeeringConnection {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CreateVpcPeeringConnection', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateVpnConnection {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CreateVpnConnection', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateVpnConnectionRoute {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CreateVpnConnectionRoute', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateVpnGateway {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::CreateVpnGateway', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteCustomerGateway {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DeleteCustomerGateway', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteDhcpOptions {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DeleteDhcpOptions', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteFlowLogs {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DeleteFlowLogs', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteInternetGateway {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DeleteInternetGateway', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteKeyPair {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DeleteKeyPair', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteNetworkAcl {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DeleteNetworkAcl', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteNetworkAclEntry {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DeleteNetworkAclEntry', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteNetworkInterface {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DeleteNetworkInterface', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeletePlacementGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DeletePlacementGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteRoute {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DeleteRoute', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteRouteTable {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DeleteRouteTable', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteSecurityGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DeleteSecurityGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteSnapshot {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DeleteSnapshot', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteSpotDatafeedSubscription {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DeleteSpotDatafeedSubscription', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteSubnet {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DeleteSubnet', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteTags {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DeleteTags', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteVolume {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DeleteVolume', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteVpc {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DeleteVpc', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteVpcEndpoints {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DeleteVpcEndpoints', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteVpcPeeringConnection {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DeleteVpcPeeringConnection', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteVpnConnection {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DeleteVpnConnection', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteVpnConnectionRoute {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DeleteVpnConnectionRoute', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteVpnGateway {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DeleteVpnGateway', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeregisterImage {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DeregisterImage', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeAccountAttributes {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeAccountAttributes', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeAddresses {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeAddresses', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeAvailabilityZones {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeAvailabilityZones', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeBundleTasks {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeBundleTasks', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeClassicLinkInstances {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeClassicLinkInstances', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeConversionTasks {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeConversionTasks', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeCustomerGateways {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeCustomerGateways', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeDhcpOptions {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeDhcpOptions', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeExportTasks {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeExportTasks', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeFlowLogs {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeFlowLogs', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeImageAttribute {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeImageAttribute', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeImages {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeImages', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeImportImageTasks {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeImportImageTasks', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeImportSnapshotTasks {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeImportSnapshotTasks', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeInstanceAttribute {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeInstanceAttribute', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeInstances {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeInstances', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeInstanceStatus {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeInstanceStatus', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeInternetGateways {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeInternetGateways', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeKeyPairs {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeKeyPairs', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeMovingAddresses {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeMovingAddresses', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeNetworkAcls {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeNetworkAcls', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeNetworkInterfaceAttribute {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeNetworkInterfaceAttribute', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeNetworkInterfaces {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeNetworkInterfaces', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribePlacementGroups {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribePlacementGroups', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribePrefixLists {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribePrefixLists', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeRegions {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeRegions', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeReservedInstances {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeReservedInstances', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeReservedInstancesListings {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeReservedInstancesListings', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeReservedInstancesModifications {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeReservedInstancesModifications', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeReservedInstancesOfferings {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeReservedInstancesOfferings', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeRouteTables {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeRouteTables', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeSecurityGroups {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeSecurityGroups', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeSnapshotAttribute {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeSnapshotAttribute', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeSnapshots {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeSnapshots', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeSpotDatafeedSubscription {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeSpotDatafeedSubscription', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeSpotFleetInstances {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeSpotFleetInstances', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeSpotFleetRequestHistory {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeSpotFleetRequestHistory', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeSpotFleetRequests {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeSpotFleetRequests', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeSpotInstanceRequests {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeSpotInstanceRequests', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeSpotPriceHistory {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeSpotPriceHistory', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeSubnets {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeSubnets', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeTags {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeTags', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeVolumeAttribute {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeVolumeAttribute', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeVolumes {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeVolumes', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeVolumeStatus {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeVolumeStatus', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeVpcAttribute {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeVpcAttribute', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeVpcClassicLink {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeVpcClassicLink', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeVpcEndpoints {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeVpcEndpoints', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeVpcEndpointServices {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeVpcEndpointServices', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeVpcPeeringConnections {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeVpcPeeringConnections', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeVpcs {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeVpcs', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeVpnConnections {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeVpnConnections', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeVpnGateways {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DescribeVpnGateways', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DetachClassicLinkVpc {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DetachClassicLinkVpc', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DetachInternetGateway {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DetachInternetGateway', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DetachNetworkInterface {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DetachNetworkInterface', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DetachVolume {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DetachVolume', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DetachVpnGateway {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DetachVpnGateway', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DisableVgwRoutePropagation {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DisableVgwRoutePropagation', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DisableVpcClassicLink {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DisableVpcClassicLink', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DisassociateAddress {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DisassociateAddress', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DisassociateRouteTable {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::DisassociateRouteTable', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub EnableVgwRoutePropagation {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::EnableVgwRoutePropagation', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub EnableVolumeIO {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::EnableVolumeIO', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub EnableVpcClassicLink {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::EnableVpcClassicLink', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetConsoleOutput {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::GetConsoleOutput', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetPasswordData {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::GetPasswordData', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ImportImage {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::ImportImage', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ImportInstance {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::ImportInstance', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ImportKeyPair {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::ImportKeyPair', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ImportSnapshot {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::ImportSnapshot', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ImportVolume {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::ImportVolume', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ModifyImageAttribute {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::ModifyImageAttribute', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ModifyInstanceAttribute {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::ModifyInstanceAttribute', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ModifyNetworkInterfaceAttribute {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::ModifyNetworkInterfaceAttribute', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ModifyReservedInstances {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::ModifyReservedInstances', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ModifySnapshotAttribute {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::ModifySnapshotAttribute', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ModifySubnetAttribute {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::ModifySubnetAttribute', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ModifyVolumeAttribute {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::ModifyVolumeAttribute', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ModifyVpcAttribute {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::ModifyVpcAttribute', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ModifyVpcEndpoint {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::ModifyVpcEndpoint', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub MonitorInstances {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::MonitorInstances', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub MoveAddressToVpc {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::MoveAddressToVpc', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub PurchaseReservedInstancesOffering {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::PurchaseReservedInstancesOffering', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RebootInstances {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::RebootInstances', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RegisterImage {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::RegisterImage', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RejectVpcPeeringConnection {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::RejectVpcPeeringConnection', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ReleaseAddress {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::ReleaseAddress', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ReplaceNetworkAclAssociation {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::ReplaceNetworkAclAssociation', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ReplaceNetworkAclEntry {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::ReplaceNetworkAclEntry', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ReplaceRoute {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::ReplaceRoute', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ReplaceRouteTableAssociation {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::ReplaceRouteTableAssociation', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ReportInstanceStatus {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::ReportInstanceStatus', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RequestSpotFleet {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::RequestSpotFleet', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RequestSpotInstances {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::RequestSpotInstances', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ResetImageAttribute {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::ResetImageAttribute', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ResetInstanceAttribute {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::ResetInstanceAttribute', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ResetNetworkInterfaceAttribute {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::ResetNetworkInterfaceAttribute', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ResetSnapshotAttribute {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::ResetSnapshotAttribute', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RestoreAddressToClassic {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::RestoreAddressToClassic', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RevokeSecurityGroupEgress {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::RevokeSecurityGroupEgress', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RevokeSecurityGroupIngress {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::RevokeSecurityGroupIngress', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RunInstances {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::RunInstances', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub StartInstances {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::StartInstances', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub StopInstances {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::StopInstances', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub TerminateInstances {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::TerminateInstances', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UnassignPrivateIpAddresses {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::UnassignPrivateIpAddresses', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UnmonitorInstances {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EC2::UnmonitorInstances', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeAllInstances {
    my $self = shift;

    my $result = $self->DescribeInstances(@_);
    my $array = [];
    push @$array, @{ $result->Reservations };

    while ($result->NextToken) {
      $result = $self->DescribeInstances(@_, NextToken => $result->NextToken);
      push @$array, @{ $result->Reservations };
    }

    return 'Paws::EC2::DescribeInstances'->_returns->new(Reservations => $array);
  }
  sub DescribeAllInstanceStatus {
    my $self = shift;

    my $result = $self->DescribeInstanceStatus(@_);
    my $array = [];
    push @$array, @{ $result->InstanceStatuses };

    while ($result->NextToken) {
      $result = $self->DescribeInstanceStatus(@_, NextToken => $result->NextToken);
      push @$array, @{ $result->InstanceStatuses };
    }

    return 'Paws::EC2::DescribeInstanceStatus'->_returns->new(InstanceStatuses => $array);
  }
  sub DescribeAllReservedInstancesModifications {
    my $self = shift;

    my $result = $self->DescribeReservedInstancesModifications(@_);
    my $array = [];
    push @$array, @{ $result->ReservedInstancesModifications };

    while ($result->NextToken) {
      $result = $self->DescribeReservedInstancesModifications(@_, NextToken => $result->NextToken);
      push @$array, @{ $result->ReservedInstancesModifications };
    }

    return 'Paws::EC2::DescribeReservedInstancesModifications'->_returns->new(ReservedInstancesModifications => $array);
  }
  sub DescribeAllReservedInstancesOfferings {
    my $self = shift;

    my $result = $self->DescribeReservedInstancesOfferings(@_);
    my $array = [];
    push @$array, @{ $result->ReservedInstancesOfferings };

    while ($result->NextToken) {
      $result = $self->DescribeReservedInstancesOfferings(@_, NextToken => $result->NextToken);
      push @$array, @{ $result->ReservedInstancesOfferings };
    }

    return 'Paws::EC2::DescribeReservedInstancesOfferings'->_returns->new(ReservedInstancesOfferings => $array);
  }
  sub DescribeAllSnapshots {
    my $self = shift;

    my $result = $self->DescribeSnapshots(@_);
    my $array = [];
    push @$array, @{ $result->Snapshots };

    while ($result->NextToken) {
      $result = $self->DescribeSnapshots(@_, NextToken => $result->NextToken);
      push @$array, @{ $result->Snapshots };
    }

    return 'Paws::EC2::DescribeSnapshots'->_returns->new(Snapshots => $array);
  }
  sub DescribeAllSpotPriceHistory {
    my $self = shift;

    my $result = $self->DescribeSpotPriceHistory(@_);
    my $array = [];
    push @$array, @{ $result->SpotPriceHistory };

    while ($result->NextToken) {
      $result = $self->DescribeSpotPriceHistory(@_, NextToken => $result->NextToken);
      push @$array, @{ $result->SpotPriceHistory };
    }

    return 'Paws::EC2::DescribeSpotPriceHistory'->_returns->new(SpotPriceHistory => $array);
  }
  sub DescribeAllTags {
    my $self = shift;

    my $result = $self->DescribeTags(@_);
    my $array = [];
    push @$array, @{ $result->Tags };

    while ($result->NextToken) {
      $result = $self->DescribeTags(@_, NextToken => $result->NextToken);
      push @$array, @{ $result->Tags };
    }

    return 'Paws::EC2::DescribeTags'->_returns->new(Tags => $array);
  }
  sub DescribeAllVolumeStatus {
    my $self = shift;

    my $result = $self->DescribeVolumeStatus(@_);
    my $array = [];
    push @$array, @{ $result->VolumeStatuses };

    while ($result->NextToken) {
      $result = $self->DescribeVolumeStatus(@_, NextToken => $result->NextToken);
      push @$array, @{ $result->VolumeStatuses };
    }

    return 'Paws::EC2::DescribeVolumeStatus'->_returns->new(VolumeStatuses => $array);
  }
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2 - Perl Interface to AWS Amazon Elastic Compute Cloud

=head1 SYNOPSIS

  use Paws;

  my $obj = Paws->service('EC2')->new;
  my $res = $obj->Method(
    Arg1 => $val1,
    Arg2 => [ 'V1', 'V2' ],
    # if Arg3 is an object, the HashRef will be used as arguments to the constructor
    # of the arguments type
    Arg3 => { Att1 => 'Val1' },
    # if Arg4 is an array of objects, the HashRefs will be passed as arguments to
    # the constructor of the arguments type
    Arg4 => [ { Att1 => 'Val1'  }, { Att1 => 'Val2' } ],
  );

=head1 DESCRIPTION



Amazon Elastic Compute Cloud

Amazon Elastic Compute Cloud (Amazon EC2) provides resizable computing
capacity in the Amazon Web Services (AWS) cloud. Using Amazon EC2
eliminates your need to invest in hardware up front, so you can develop
and deploy applications faster.










=head1 METHODS

=head2 AcceptVpcPeeringConnection([DryRun => Bool, VpcPeeringConnectionId => Str])

Each argument is described in detail in: L<Paws::EC2::AcceptVpcPeeringConnection>

Returns: a L<Paws::EC2::AcceptVpcPeeringConnectionResult> instance

  

Accept a VPC peering connection request. To accept a request, the VPC
peering connection must be in the C<pending-acceptance> state, and you
must be the owner of the peer VPC. Use the
C<DescribeVpcPeeringConnections> request to view your outstanding VPC
peering connection requests.











=head2 AllocateAddress([Domain => Str, DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::AllocateAddress>

Returns: a L<Paws::EC2::AllocateAddressResult> instance

  

Acquires an Elastic IP address.

An Elastic IP address is for use either in the EC2-Classic platform or
in a VPC. For more information, see Elastic IP Addresses in the
I<Amazon Elastic Compute Cloud User Guide>.











=head2 AssignPrivateIpAddresses(NetworkInterfaceId => Str, [AllowReassignment => Bool, PrivateIpAddresses => ArrayRef[Str], SecondaryPrivateIpAddressCount => Int])

Each argument is described in detail in: L<Paws::EC2::AssignPrivateIpAddresses>

Returns: nothing

  

Assigns one or more secondary private IP addresses to the specified
network interface. You can specify one or more specific secondary IP
addresses, or you can specify the number of secondary IP addresses to
be automatically assigned within the subnet's CIDR block range. The
number of secondary IP addresses that you can assign to an instance
varies by instance type. For information about instance types, see
Instance Types in the I<Amazon Elastic Compute Cloud User Guide>. For
more information about Elastic IP addresses, see Elastic IP Addresses
in the I<Amazon Elastic Compute Cloud User Guide>.

AssignPrivateIpAddresses is available only in EC2-VPC.











=head2 AssociateAddress([AllocationId => Str, AllowReassociation => Bool, DryRun => Bool, InstanceId => Str, NetworkInterfaceId => Str, PrivateIpAddress => Str, PublicIp => Str])

Each argument is described in detail in: L<Paws::EC2::AssociateAddress>

Returns: a L<Paws::EC2::AssociateAddressResult> instance

  

Associates an Elastic IP address with an instance or a network
interface.

An Elastic IP address is for use in either the EC2-Classic platform or
in a VPC. For more information, see Elastic IP Addresses in the
I<Amazon Elastic Compute Cloud User Guide>.

[EC2-Classic, VPC in an EC2-VPC-only account] If the Elastic IP address
is already associated with a different instance, it is disassociated
from that instance and associated with the specified instance.

[VPC in an EC2-Classic account] If you don't specify a private IP
address, the Elastic IP address is associated with the primary IP
address. If the Elastic IP address is already associated with a
different instance or a network interface, you get an error unless you
allow reassociation.

This is an idempotent operation. If you perform the operation more than
once, Amazon EC2 doesn't return an error.











=head2 AssociateDhcpOptions(DhcpOptionsId => Str, VpcId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::AssociateDhcpOptions>

Returns: nothing

  

Associates a set of DHCP options (that you've previously created) with
the specified VPC, or associates no DHCP options with the VPC.

After you associate the options with the VPC, any existing instances
and all new instances that you launch in that VPC use the options. You
don't need to restart or relaunch the instances. They automatically
pick up the changes within a few hours, depending on how frequently the
instance renews its DHCP lease. You can explicitly renew the lease
using the operating system on the instance.

For more information, see DHCP Options Sets in the I<Amazon Virtual
Private Cloud User Guide>.











=head2 AssociateRouteTable(RouteTableId => Str, SubnetId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::AssociateRouteTable>

Returns: a L<Paws::EC2::AssociateRouteTableResult> instance

  

Associates a subnet with a route table. The subnet and route table must
be in the same VPC. This association causes traffic originating from
the subnet to be routed according to the routes in the route table. The
action returns an association ID, which you need in order to
disassociate the route table from the subnet later. A route table can
be associated with multiple subnets.

For more information about route tables, see Route Tables in the
I<Amazon Virtual Private Cloud User Guide>.











=head2 AttachClassicLinkVpc(Groups => ArrayRef[Str], InstanceId => Str, VpcId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::AttachClassicLinkVpc>

Returns: a L<Paws::EC2::AttachClassicLinkVpcResult> instance

  

Links an EC2-Classic instance to a ClassicLink-enabled VPC through one
or more of the VPC's security groups. You cannot link an EC2-Classic
instance to more than one VPC at a time. You can only link an instance
that's in the C<running> state. An instance is automatically unlinked
from a VPC when it's stopped - you can link it to the VPC again when
you restart it.

After you've linked an instance, you cannot change the VPC security
groups that are associated with it. To change the security groups, you
must first unlink the instance, and then link it again.

Linking your instance to a VPC is sometimes referred to as I<attaching>
your instance.











=head2 AttachInternetGateway(InternetGatewayId => Str, VpcId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::AttachInternetGateway>

Returns: nothing

  

Attaches an Internet gateway to a VPC, enabling connectivity between
the Internet and the VPC. For more information about your VPC and
Internet gateway, see the Amazon Virtual Private Cloud User Guide.











=head2 AttachNetworkInterface(DeviceIndex => Int, InstanceId => Str, NetworkInterfaceId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::AttachNetworkInterface>

Returns: a L<Paws::EC2::AttachNetworkInterfaceResult> instance

  

Attaches a network interface to an instance.











=head2 AttachVolume(Device => Str, InstanceId => Str, VolumeId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::AttachVolume>

Returns: a L<Paws::EC2::VolumeAttachment> instance

  

Attaches an EBS volume to a running or stopped instance and exposes it
to the instance with the specified device name.

Encrypted EBS volumes may only be attached to instances that support
Amazon EBS encryption. For more information, see Amazon EBS Encryption
in the I<Amazon Elastic Compute Cloud User Guide>.

For a list of supported device names, see Attaching an EBS Volume to an
Instance. Any device names that aren't reserved for instance store
volumes can be used for EBS volumes. For more information, see Amazon
EC2 Instance Store in the I<Amazon Elastic Compute Cloud User Guide>.

If a volume has an AWS Marketplace product code:

=over

=item * The volume can be attached only to a stopped instance.

=item * AWS Marketplace product codes are copied from the volume to the
instance.

=item * You must be subscribed to the product.

=item * The instance type and operating system of the instance must
support the product. For example, you can't detach a volume from a
Windows instance and attach it to a Linux instance.

=back

For an overview of the AWS Marketplace, see Introducing AWS
Marketplace.

For more information about EBS volumes, see Attaching Amazon EBS
Volumes in the I<Amazon Elastic Compute Cloud User Guide>.











=head2 AttachVpnGateway(VpcId => Str, VpnGatewayId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::AttachVpnGateway>

Returns: a L<Paws::EC2::AttachVpnGatewayResult> instance

  

Attaches a virtual private gateway to a VPC. For more information, see
Adding a Hardware Virtual Private Gateway to Your VPC in the I<Amazon
Virtual Private Cloud User Guide>.











=head2 AuthorizeSecurityGroupEgress(GroupId => Str, [CidrIp => Str, DryRun => Bool, FromPort => Int, IpPermissions => ArrayRef[Paws::EC2::IpPermission], IpProtocol => Str, SourceSecurityGroupName => Str, SourceSecurityGroupOwnerId => Str, ToPort => Int])

Each argument is described in detail in: L<Paws::EC2::AuthorizeSecurityGroupEgress>

Returns: nothing

  

Adds one or more egress rules to a security group for use with a VPC.
Specifically, this action permits instances to send traffic to one or
more destination CIDR IP address ranges, or to one or more destination
security groups for the same VPC.

You can have up to 50 rules per security group (covering both ingress
and egress rules).

A security group is for use with instances either in the EC2-Classic
platform or in a specific VPC. This action doesn't apply to security
groups for use in EC2-Classic. For more information, see Security
Groups for Your VPC in the I<Amazon Virtual Private Cloud User Guide>.

Each rule consists of the protocol (for example, TCP), plus either a
CIDR range or a source group. For the TCP and UDP protocols, you must
also specify the destination port or port range. For the ICMP protocol,
you must also specify the ICMP type and code. You can use -1 for the
type or code to mean all types or all codes.

Rule changes are propagated to affected instances as quickly as
possible. However, a small delay might occur.











=head2 AuthorizeSecurityGroupIngress([CidrIp => Str, DryRun => Bool, FromPort => Int, GroupId => Str, GroupName => Str, IpPermissions => ArrayRef[Paws::EC2::IpPermission], IpProtocol => Str, SourceSecurityGroupName => Str, SourceSecurityGroupOwnerId => Str, ToPort => Int])

Each argument is described in detail in: L<Paws::EC2::AuthorizeSecurityGroupIngress>

Returns: nothing

  

Adds one or more ingress rules to a security group.

EC2-Classic: You can have up to 100 rules per group.

EC2-VPC: You can have up to 50 rules per group (covering both ingress
and egress rules).

Rule changes are propagated to instances within the security group as
quickly as possible. However, a small delay might occur.

[EC2-Classic] This action gives one or more CIDR IP address ranges
permission to access a security group in your account, or gives one or
more security groups (called the I<source groups>) permission to access
a security group for your account. A source group can be for your own
AWS account, or another.

[EC2-VPC] This action gives one or more CIDR IP address ranges
permission to access a security group in your VPC, or gives one or more
other security groups (called the I<source groups>) permission to
access a security group for your VPC. The security groups must all be
for the same VPC.











=head2 BundleInstance(InstanceId => Str, Storage => Paws::EC2::Storage, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::BundleInstance>

Returns: a L<Paws::EC2::BundleInstanceResult> instance

  

Bundles an Amazon instance store-backed Windows instance.

During bundling, only the root device volume (C:\) is bundled. Data on
other instance store volumes is not preserved.

This action is not applicable for Linux/Unix instances or Windows
instances that are backed by Amazon EBS.

For more information, see Creating an Instance Store-Backed Windows
AMI.











=head2 CancelBundleTask(BundleId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::CancelBundleTask>

Returns: a L<Paws::EC2::CancelBundleTaskResult> instance

  

Cancels a bundling operation for an instance store-backed Windows
instance.











=head2 CancelConversionTask(ConversionTaskId => Str, [DryRun => Bool, ReasonMessage => Str])

Each argument is described in detail in: L<Paws::EC2::CancelConversionTask>

Returns: nothing

  

Cancels an active conversion task. The task can be the import of an
instance or volume. The action removes all artifacts of the conversion,
including a partially uploaded volume or instance. If the conversion is
complete or is in the process of transferring the final disk image, the
command fails and returns an exception.

For more information, see Using the Command Line Tools to Import Your
Virtual Machine to Amazon EC2 in the I<Amazon Elastic Compute Cloud
User Guide>.











=head2 CancelExportTask(ExportTaskId => Str)

Each argument is described in detail in: L<Paws::EC2::CancelExportTask>

Returns: nothing

  

Cancels an active export task. The request removes all artifacts of the
export, including any partially-created Amazon S3 objects. If the
export task is complete or is in the process of transferring the final
disk image, the command fails and returns an error.











=head2 CancelImportTask([CancelReason => Str, DryRun => Bool, ImportTaskId => Str])

Each argument is described in detail in: L<Paws::EC2::CancelImportTask>

Returns: a L<Paws::EC2::CancelImportTaskResult> instance

  

Cancels an in-process import virtual machine or import snapshot task.











=head2 CancelReservedInstancesListing(ReservedInstancesListingId => Str)

Each argument is described in detail in: L<Paws::EC2::CancelReservedInstancesListing>

Returns: a L<Paws::EC2::CancelReservedInstancesListingResult> instance

  

Cancels the specified Reserved Instance listing in the Reserved
Instance Marketplace.

For more information, see Reserved Instance Marketplace in the I<Amazon
Elastic Compute Cloud User Guide>.











=head2 CancelSpotFleetRequests(SpotFleetRequestIds => ArrayRef[Str], TerminateInstances => Bool, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::CancelSpotFleetRequests>

Returns: a L<Paws::EC2::CancelSpotFleetRequestsResponse> instance

  

Cancels the specified Spot fleet requests.











=head2 CancelSpotInstanceRequests(SpotInstanceRequestIds => ArrayRef[Str], [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::CancelSpotInstanceRequests>

Returns: a L<Paws::EC2::CancelSpotInstanceRequestsResult> instance

  

Cancels one or more Spot Instance requests. Spot Instances are
instances that Amazon EC2 starts on your behalf when the bid price that
you specify exceeds the current Spot Price. Amazon EC2 periodically
sets the Spot Price based on available Spot Instance capacity and
current Spot Instance requests. For more information, see Spot Instance
Requests in the I<Amazon Elastic Compute Cloud User Guide>.

Canceling a Spot Instance request does not terminate running Spot
Instances associated with the request.











=head2 ConfirmProductInstance(InstanceId => Str, ProductCode => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::ConfirmProductInstance>

Returns: a L<Paws::EC2::ConfirmProductInstanceResult> instance

  

Determines whether a product code is associated with an instance. This
action can only be used by the owner of the product code. It is useful
when a product code owner needs to verify whether another user's
instance is eligible for support.











=head2 CopyImage(Name => Str, SourceImageId => Str, SourceRegion => Str, [ClientToken => Str, Description => Str, DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::CopyImage>

Returns: a L<Paws::EC2::CopyImageResult> instance

  

Initiates the copy of an AMI from the specified source region to the
current region. You specify the destination region by using its
endpoint when making the request. AMIs that use encrypted EBS snapshots
cannot be copied with this method.

For more information, see Copying AMIs in the I<Amazon Elastic Compute
Cloud User Guide>.











=head2 CopySnapshot(SourceRegion => Str, SourceSnapshotId => Str, [Description => Str, DestinationRegion => Str, DryRun => Bool, PresignedUrl => Str])

Each argument is described in detail in: L<Paws::EC2::CopySnapshot>

Returns: a L<Paws::EC2::CopySnapshotResult> instance

  

Copies a point-in-time snapshot of an EBS volume and stores it in
Amazon S3. You can copy the snapshot within the same region or from one
region to another. You can use the snapshot to create EBS volumes or
Amazon Machine Images (AMIs). The snapshot is copied to the regional
endpoint that you send the HTTP request to.

Copies of encrypted EBS snapshots remain encrypted. Copies of
unencrypted snapshots remain unencrypted.

Copying snapshots that were encrypted with non-default AWS Key
Management Service (KMS) master keys is not supported at this time.

For more information, see Copying an Amazon EBS Snapshot in the
I<Amazon Elastic Compute Cloud User Guide>.











=head2 CreateCustomerGateway(BgpAsn => Int, PublicIp => Str, Type => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::CreateCustomerGateway>

Returns: a L<Paws::EC2::CreateCustomerGatewayResult> instance

  

Provides information to AWS about your VPN customer gateway device. The
customer gateway is the appliance at your end of the VPN connection.
(The device on the AWS side of the VPN connection is the virtual
private gateway.) You must provide the Internet-routable IP address of
the customer gateway's external interface. The IP address must be
static and can't be behind a device performing network address
translation (NAT).

For devices that use Border Gateway Protocol (BGP), you can also
provide the device's BGP Autonomous System Number (ASN). You can use an
existing ASN assigned to your network. If you don't have an ASN
already, you can use a private ASN (in the 64512 - 65534 range).

Amazon EC2 supports all 2-byte ASN numbers in the range of 1 - 65534,
with the exception of 7224, which is reserved in the C<us-east-1>
region, and 9059, which is reserved in the C<eu-west-1> region.

For more information about VPN customer gateways, see Adding a Hardware
Virtual Private Gateway to Your VPC in the I<Amazon Virtual Private
Cloud User Guide>.

You cannot create more than one customer gateway with the same VPN
type, IP address, and BGP ASN parameter values. If you run an identical
request more than one time, the first request creates the customer
gateway, and subsequent requests return information about the existing
customer gateway. The subsequent requests do not create new customer
gateway resources.











=head2 CreateDhcpOptions(DhcpConfigurations => ArrayRef[Paws::EC2::NewDhcpConfiguration], [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::CreateDhcpOptions>

Returns: a L<Paws::EC2::CreateDhcpOptionsResult> instance

  

Creates a set of DHCP options for your VPC. After creating the set, you
must associate it with the VPC, causing all existing and new instances
that you launch in the VPC to use this set of DHCP options. The
following are the individual DHCP options you can specify. For more
information about the options, see RFC 2132.

=over

=item * C<domain-name-servers> - The IP addresses of up to four domain
name servers, or C<AmazonProvidedDNS>. The default DHCP option set
specifies C<AmazonProvidedDNS>. If specifying more than one domain name
server, specify the IP addresses in a single parameter, separated by
commas.

=item * C<domain-name> - If you're using AmazonProvidedDNS in
C<us-east-1>, specify C<ec2.internal>. If you're using
AmazonProvidedDNS in another region, specify C<region.compute.internal>
(for example, C<ap-northeast-1.compute.internal>). Otherwise, specify a
domain name (for example, C<MyCompany.com>). B<Important>: Some Linux
operating systems accept multiple domain names separated by spaces.
However, Windows and other Linux operating systems treat the value as a
single domain, which results in unexpected behavior. If your DHCP
options set is associated with a VPC that has instances with multiple
operating systems, specify only one domain name.

=item * C<ntp-servers> - The IP addresses of up to four Network Time
Protocol (NTP) servers.

=item * C<netbios-name-servers> - The IP addresses of up to four
NetBIOS name servers.

=item * C<netbios-node-type> - The NetBIOS node type (1, 2, 4, or 8).
We recommend that you specify 2 (broadcast and multicast are not
currently supported). For more information about these node types, see
RFC 2132.

=back

Your VPC automatically starts out with a set of DHCP options that
includes only a DNS server that we provide (AmazonProvidedDNS). If you
create a set of options, and if your VPC has an Internet gateway, make
sure to set the C<domain-name-servers> option either to
C<AmazonProvidedDNS> or to a domain name server of your choice. For
more information about DHCP options, see DHCP Options Sets in the
I<Amazon Virtual Private Cloud User Guide>.











=head2 CreateFlowLogs(DeliverLogsPermissionArn => Str, LogGroupName => Str, ResourceIds => ArrayRef[Str], ResourceType => Str, TrafficType => Str, [ClientToken => Str])

Each argument is described in detail in: L<Paws::EC2::CreateFlowLogs>

Returns: a L<Paws::EC2::CreateFlowLogsResult> instance

  

Creates one or more flow logs to capture IP traffic for a specific
network interface, subnet, or VPC. Flow logs are delivered to a
specified log group in Amazon CloudWatch Logs. If you specify a VPC or
subnet in the request, a log stream is created in CloudWatch Logs for
each network interface in the subnet or VPC. Log streams can include
information about accepted and rejected traffic to a network interface.
You can view the data in your log streams using Amazon CloudWatch Logs.

In your request, you must also specify an IAM role that has permission
to publish logs to CloudWatch Logs.











=head2 CreateImage(InstanceId => Str, Name => Str, [BlockDeviceMappings => ArrayRef[Paws::EC2::BlockDeviceMapping], Description => Str, DryRun => Bool, NoReboot => Bool])

Each argument is described in detail in: L<Paws::EC2::CreateImage>

Returns: a L<Paws::EC2::CreateImageResult> instance

  

Creates an Amazon EBS-backed AMI from an Amazon EBS-backed instance
that is either running or stopped.

If you customized your instance with instance store volumes or EBS
volumes in addition to the root device volume, the new AMI contains
block device mapping information for those volumes. When you launch an
instance from this new AMI, the instance automatically launches with
those additional volumes.

For more information, see Creating Amazon EBS-Backed Linux AMIs in the
I<Amazon Elastic Compute Cloud User Guide>.











=head2 CreateInstanceExportTask(InstanceId => Str, [Description => Str, ExportToS3Task => Paws::EC2::ExportToS3TaskSpecification, TargetEnvironment => Str])

Each argument is described in detail in: L<Paws::EC2::CreateInstanceExportTask>

Returns: a L<Paws::EC2::CreateInstanceExportTaskResult> instance

  

Exports a running or stopped instance to an S3 bucket.

For information about the supported operating systems, image formats,
and known limitations for the types of instances you can export, see
Exporting EC2 Instances in the I<Amazon Elastic Compute Cloud User
Guide>.











=head2 CreateInternetGateway([DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::CreateInternetGateway>

Returns: a L<Paws::EC2::CreateInternetGatewayResult> instance

  

Creates an Internet gateway for use with a VPC. After creating the
Internet gateway, you attach it to a VPC using AttachInternetGateway.

For more information about your VPC and Internet gateway, see the
Amazon Virtual Private Cloud User Guide.











=head2 CreateKeyPair(KeyName => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::CreateKeyPair>

Returns: a L<Paws::EC2::KeyPair> instance

  

Creates a 2048-bit RSA key pair with the specified name. Amazon EC2
stores the public key and displays the private key for you to save to a
file. The private key is returned as an unencrypted PEM encoded PKCS
private key. If a key with the specified name already exists, Amazon
EC2 returns an error.

You can have up to five thousand key pairs per region.

The key pair returned to you is available only in the region in which
you create it. To create a key pair that is available in all regions,
use ImportKeyPair.

For more information about key pairs, see Key Pairs in the I<Amazon
Elastic Compute Cloud User Guide>.











=head2 CreateNetworkAcl(VpcId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::CreateNetworkAcl>

Returns: a L<Paws::EC2::CreateNetworkAclResult> instance

  

Creates a network ACL in a VPC. Network ACLs provide an optional layer
of security (in addition to security groups) for the instances in your
VPC.

For more information about network ACLs, see Network ACLs in the
I<Amazon Virtual Private Cloud User Guide>.











=head2 CreateNetworkAclEntry(CidrBlock => Str, Egress => Bool, NetworkAclId => Str, Protocol => Str, RuleAction => Str, RuleNumber => Int, [DryRun => Bool, IcmpTypeCode => Paws::EC2::IcmpTypeCode, PortRange => Paws::EC2::PortRange])

Each argument is described in detail in: L<Paws::EC2::CreateNetworkAclEntry>

Returns: nothing

  

Creates an entry (a rule) in a network ACL with the specified rule
number. Each network ACL has a set of numbered ingress rules and a
separate set of numbered egress rules. When determining whether a
packet should be allowed in or out of a subnet associated with the ACL,
we process the entries in the ACL according to the rule numbers, in
ascending order. Each network ACL has a set of ingress rules and a
separate set of egress rules.

We recommend that you leave room between the rule numbers (for example,
100, 110, 120, ...), and not number them one right after the other (for
example, 101, 102, 103, ...). This makes it easier to add a rule
between existing ones without having to renumber the rules.

After you add an entry, you can't modify it; you must either replace
it, or create an entry and delete the old one.

For more information about network ACLs, see Network ACLs in the
I<Amazon Virtual Private Cloud User Guide>.











=head2 CreateNetworkInterface(SubnetId => Str, [Description => Str, DryRun => Bool, Groups => ArrayRef[Str], PrivateIpAddress => Str, PrivateIpAddresses => ArrayRef[Paws::EC2::PrivateIpAddressSpecification], SecondaryPrivateIpAddressCount => Int])

Each argument is described in detail in: L<Paws::EC2::CreateNetworkInterface>

Returns: a L<Paws::EC2::CreateNetworkInterfaceResult> instance

  

Creates a network interface in the specified subnet.

For more information about network interfaces, see Elastic Network
Interfaces in the I<Amazon Elastic Compute Cloud User Guide>.











=head2 CreatePlacementGroup(GroupName => Str, Strategy => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::CreatePlacementGroup>

Returns: nothing

  

Creates a placement group that you launch cluster instances into. You
must give the group a name that's unique within the scope of your
account.

For more information about placement groups and cluster instances, see
Cluster Instances in the I<Amazon Elastic Compute Cloud User Guide>.











=head2 CreateReservedInstancesListing(ClientToken => Str, InstanceCount => Int, PriceSchedules => ArrayRef[Paws::EC2::PriceScheduleSpecification], ReservedInstancesId => Str)

Each argument is described in detail in: L<Paws::EC2::CreateReservedInstancesListing>

Returns: a L<Paws::EC2::CreateReservedInstancesListingResult> instance

  

Creates a listing for Amazon EC2 Reserved Instances to be sold in the
Reserved Instance Marketplace. You can submit one Reserved Instance
listing at a time. To get a list of your Reserved Instances, you can
use the DescribeReservedInstances operation.

The Reserved Instance Marketplace matches sellers who want to resell
Reserved Instance capacity that they no longer need with buyers who
want to purchase additional capacity. Reserved Instances bought and
sold through the Reserved Instance Marketplace work like any other
Reserved Instances.

To sell your Reserved Instances, you must first register as a seller in
the Reserved Instance Marketplace. After completing the registration
process, you can create a Reserved Instance Marketplace listing of some
or all of your Reserved Instances, and specify the upfront price to
receive for them. Your Reserved Instance listings then become available
for purchase. To view the details of your Reserved Instance listing,
you can use the DescribeReservedInstancesListings operation.

For more information, see Reserved Instance Marketplace in the I<Amazon
Elastic Compute Cloud User Guide>.











=head2 CreateRoute(DestinationCidrBlock => Str, RouteTableId => Str, [ClientToken => Str, DryRun => Bool, GatewayId => Str, InstanceId => Str, NetworkInterfaceId => Str, VpcPeeringConnectionId => Str])

Each argument is described in detail in: L<Paws::EC2::CreateRoute>

Returns: a L<Paws::EC2::CreateRouteResult> instance

  

Creates a route in a route table within a VPC.

You must specify one of the following targets: Internet gateway or
virtual private gateway, NAT instance, VPC peering connection, or
network interface.

When determining how to route traffic, we use the route with the most
specific match. For example, let's say the traffic is destined for
C<192.0.2.3>, and the route table includes the following two routes:

=over

=item *

C<192.0.2.0/24> (goes to some target A)

=item *

C<192.0.2.0/28> (goes to some target B)

=back

Both routes apply to the traffic destined for C<192.0.2.3>. However,
the second route in the list covers a smaller number of IP addresses
and is therefore more specific, so we use that route to determine where
to target the traffic.

For more information about route tables, see Route Tables in the
I<Amazon Virtual Private Cloud User Guide>.











=head2 CreateRouteTable(VpcId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::CreateRouteTable>

Returns: a L<Paws::EC2::CreateRouteTableResult> instance

  

Creates a route table for the specified VPC. After you create a route
table, you can add routes and associate the table with a subnet.

For more information about route tables, see Route Tables in the
I<Amazon Virtual Private Cloud User Guide>.











=head2 CreateSecurityGroup(Description => Str, GroupName => Str, [DryRun => Bool, VpcId => Str])

Each argument is described in detail in: L<Paws::EC2::CreateSecurityGroup>

Returns: a L<Paws::EC2::CreateSecurityGroupResult> instance

  

Creates a security group.

A security group is for use with instances either in the EC2-Classic
platform or in a specific VPC. For more information, see Amazon EC2
Security Groups in the I<Amazon Elastic Compute Cloud User Guide> and
Security Groups for Your VPC in the I<Amazon Virtual Private Cloud User
Guide>.

EC2-Classic: You can have up to 500 security groups.

EC2-VPC: You can create up to 100 security groups per VPC.

When you create a security group, you specify a friendly name of your
choice. You can have a security group for use in EC2-Classic with the
same name as a security group for use in a VPC. However, you can't have
two security groups for use in EC2-Classic with the same name or two
security groups for use in a VPC with the same name.

You have a default security group for use in EC2-Classic and a default
security group for use in your VPC. If you don't specify a security
group when you launch an instance, the instance is launched into the
appropriate default security group. A default security group includes a
default rule that grants instances unrestricted network access to each
other.

You can add or remove rules from your security groups using
AuthorizeSecurityGroupIngress, AuthorizeSecurityGroupEgress,
RevokeSecurityGroupIngress, and RevokeSecurityGroupEgress.











=head2 CreateSnapshot(VolumeId => Str, [Description => Str, DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::CreateSnapshot>

Returns: a L<Paws::EC2::Snapshot> instance

  

Creates a snapshot of an EBS volume and stores it in Amazon S3. You can
use snapshots for backups, to make copies of EBS volumes, and to save
data before shutting down an instance.

When a snapshot is created, any AWS Marketplace product codes that are
associated with the source volume are propagated to the snapshot.

You can take a snapshot of an attached volume that is in use. However,
snapshots only capture data that has been written to your EBS volume at
the time the snapshot command is issued; this may exclude any data that
has been cached by any applications or the operating system. If you can
pause any file systems on the volume long enough to take a snapshot,
your snapshot should be complete. However, if you cannot pause all file
writes to the volume, you should unmount the volume from within the
instance, issue the snapshot command, and then remount the volume to
ensure a consistent and complete snapshot. You may remount and use your
volume while the snapshot status is C<pending>.

To create a snapshot for EBS volumes that serve as root devices, you
should stop the instance before taking the snapshot.

Snapshots that are taken from encrypted volumes are automatically
encrypted. Volumes that are created from encrypted snapshots are also
automatically encrypted. Your encrypted volumes and any associated
snapshots always remain protected.

For more information, see Amazon Elastic Block Store and Amazon EBS
Encryption in the I<Amazon Elastic Compute Cloud User Guide>.











=head2 CreateSpotDatafeedSubscription(Bucket => Str, [DryRun => Bool, Prefix => Str])

Each argument is described in detail in: L<Paws::EC2::CreateSpotDatafeedSubscription>

Returns: a L<Paws::EC2::CreateSpotDatafeedSubscriptionResult> instance

  

Creates a data feed for Spot Instances, enabling you to view Spot
Instance usage logs. You can create one data feed per AWS account. For
more information, see Spot Instance Data Feed in the I<Amazon Elastic
Compute Cloud User Guide>.











=head2 CreateSubnet(CidrBlock => Str, VpcId => Str, [AvailabilityZone => Str, DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::CreateSubnet>

Returns: a L<Paws::EC2::CreateSubnetResult> instance

  

Creates a subnet in an existing VPC.

When you create each subnet, you provide the VPC ID and the CIDR block
you want for the subnet. After you create a subnet, you can't change
its CIDR block. The subnet's CIDR block can be the same as the VPC's
CIDR block (assuming you want only a single subnet in the VPC), or a
subset of the VPC's CIDR block. If you create more than one subnet in a
VPC, the subnets' CIDR blocks must not overlap. The smallest subnet
(and VPC) you can create uses a /28 netmask (16 IP addresses), and the
largest uses a /16 netmask (65,536 IP addresses).

AWS reserves both the first four and the last IP address in each
subnet's CIDR block. They're not available for use.

If you add more than one subnet to a VPC, they're set up in a star
topology with a logical router in the middle.

If you launch an instance in a VPC using an Amazon EBS-backed AMI, the
IP address doesn't change if you stop and restart the instance (unlike
a similar instance launched outside a VPC, which gets a new IP address
when restarted). It's therefore possible to have a subnet with no
running instances (they're all stopped), but no remaining IP addresses
available.

For more information about subnets, see Your VPC and Subnets in the
I<Amazon Virtual Private Cloud User Guide>.











=head2 CreateTags(Resources => ArrayRef[Str], Tags => ArrayRef[Paws::EC2::Tag], [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::CreateTags>

Returns: nothing

  

Adds or overwrites one or more tags for the specified Amazon EC2
resource or resources. Each resource can have a maximum of 10 tags.
Each tag consists of a key and optional value. Tag keys must be unique
per resource.

For more information about tags, see Tagging Your Resources in the
I<Amazon Elastic Compute Cloud User Guide>.











=head2 CreateVolume(AvailabilityZone => Str, [DryRun => Bool, Encrypted => Bool, Iops => Int, KmsKeyId => Str, Size => Int, SnapshotId => Str, VolumeType => Str])

Each argument is described in detail in: L<Paws::EC2::CreateVolume>

Returns: a L<Paws::EC2::Volume> instance

  

Creates an EBS volume that can be attached to an instance in the same
Availability Zone. The volume is created in the regional endpoint that
you send the HTTP request to. For more information see Regions and
Endpoints.

You can create a new empty volume or restore a volume from an EBS
snapshot. Any AWS Marketplace product codes from the snapshot are
propagated to the volume.

You can create encrypted volumes with the C<Encrypted> parameter.
Encrypted volumes may only be attached to instances that support Amazon
EBS encryption. Volumes that are created from encrypted snapshots are
also automatically encrypted. For more information, see Amazon EBS
Encryption in the I<Amazon Elastic Compute Cloud User Guide>.

For more information, see Creating or Restoring an Amazon EBS Volume in
the I<Amazon Elastic Compute Cloud User Guide>.











=head2 CreateVpc(CidrBlock => Str, [DryRun => Bool, InstanceTenancy => Str])

Each argument is described in detail in: L<Paws::EC2::CreateVpc>

Returns: a L<Paws::EC2::CreateVpcResult> instance

  

Creates a VPC with the specified CIDR block.

The smallest VPC you can create uses a /28 netmask (16 IP addresses),
and the largest uses a /16 netmask (65,536 IP addresses). To help you
decide how big to make your VPC, see Your VPC and Subnets in the
I<Amazon Virtual Private Cloud User Guide>.

By default, each instance you launch in the VPC has the default DHCP
options, which includes only a default DNS server that we provide
(AmazonProvidedDNS). For more information about DHCP options, see DHCP
Options Sets in the I<Amazon Virtual Private Cloud User Guide>.











=head2 CreateVpcEndpoint(ServiceName => Str, VpcId => Str, [ClientToken => Str, DryRun => Bool, PolicyDocument => Str, RouteTableIds => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EC2::CreateVpcEndpoint>

Returns: a L<Paws::EC2::CreateVpcEndpointResult> instance

  

Creates a VPC endpoint for a specified AWS service. An endpoint enables
you to create a private connection between your VPC and another AWS
service in your account. You can specify an endpoint policy to attach
to the endpoint that will control access to the service from your VPC.
You can also specify the VPC route tables that use the endpoint.

Currently, only endpoints to Amazon S3 are supported.











=head2 CreateVpcPeeringConnection([DryRun => Bool, PeerOwnerId => Str, PeerVpcId => Str, VpcId => Str])

Each argument is described in detail in: L<Paws::EC2::CreateVpcPeeringConnection>

Returns: a L<Paws::EC2::CreateVpcPeeringConnectionResult> instance

  

Requests a VPC peering connection between two VPCs: a requester VPC
that you own and a peer VPC with which to create the connection. The
peer VPC can belong to another AWS account. The requester VPC and peer
VPC cannot have overlapping CIDR blocks.

The owner of the peer VPC must accept the peering request to activate
the peering connection. The VPC peering connection request expires
after 7 days, after which it cannot be accepted or rejected.

A C<CreateVpcPeeringConnection> request between VPCs with overlapping
CIDR blocks results in the VPC peering connection having a status of
C<failed>.











=head2 CreateVpnConnection(CustomerGatewayId => Str, Type => Str, VpnGatewayId => Str, [DryRun => Bool, Options => Paws::EC2::VpnConnectionOptionsSpecification])

Each argument is described in detail in: L<Paws::EC2::CreateVpnConnection>

Returns: a L<Paws::EC2::CreateVpnConnectionResult> instance

  

Creates a VPN connection between an existing virtual private gateway
and a VPN customer gateway. The only supported connection type is
C<ipsec.1>.

The response includes information that you need to give to your network
administrator to configure your customer gateway.

We strongly recommend that you use HTTPS when calling this operation
because the response contains sensitive cryptographic information for
configuring your customer gateway.

If you decide to shut down your VPN connection for any reason and later
create a new VPN connection, you must reconfigure your customer gateway
with the new information returned from this call.

For more information about VPN connections, see Adding a Hardware
Virtual Private Gateway to Your VPC in the I<Amazon Virtual Private
Cloud User Guide>.











=head2 CreateVpnConnectionRoute(DestinationCidrBlock => Str, VpnConnectionId => Str)

Each argument is described in detail in: L<Paws::EC2::CreateVpnConnectionRoute>

Returns: nothing

  

Creates a static route associated with a VPN connection between an
existing virtual private gateway and a VPN customer gateway. The static
route allows traffic to be routed from the virtual private gateway to
the VPN customer gateway.

For more information about VPN connections, see Adding a Hardware
Virtual Private Gateway to Your VPC in the I<Amazon Virtual Private
Cloud User Guide>.











=head2 CreateVpnGateway(Type => Str, [AvailabilityZone => Str, DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::CreateVpnGateway>

Returns: a L<Paws::EC2::CreateVpnGatewayResult> instance

  

Creates a virtual private gateway. A virtual private gateway is the
endpoint on the VPC side of your VPN connection. You can create a
virtual private gateway before creating the VPC itself.

For more information about virtual private gateways, see Adding a
Hardware Virtual Private Gateway to Your VPC in the I<Amazon Virtual
Private Cloud User Guide>.











=head2 DeleteCustomerGateway(CustomerGatewayId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DeleteCustomerGateway>

Returns: nothing

  

Deletes the specified customer gateway. You must delete the VPN
connection before you can delete the customer gateway.











=head2 DeleteDhcpOptions(DhcpOptionsId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DeleteDhcpOptions>

Returns: nothing

  

Deletes the specified set of DHCP options. You must disassociate the
set of DHCP options before you can delete it. You can disassociate the
set of DHCP options by associating either a new set of options or the
default set of options with the VPC.











=head2 DeleteFlowLogs(FlowLogIds => ArrayRef[Str])

Each argument is described in detail in: L<Paws::EC2::DeleteFlowLogs>

Returns: a L<Paws::EC2::DeleteFlowLogsResult> instance

  

Deletes one or more flow logs.











=head2 DeleteInternetGateway(InternetGatewayId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DeleteInternetGateway>

Returns: nothing

  

Deletes the specified Internet gateway. You must detach the Internet
gateway from the VPC before you can delete it.











=head2 DeleteKeyPair(KeyName => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DeleteKeyPair>

Returns: nothing

  

Deletes the specified key pair, by removing the public key from Amazon
EC2.











=head2 DeleteNetworkAcl(NetworkAclId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DeleteNetworkAcl>

Returns: nothing

  

Deletes the specified network ACL. You can't delete the ACL if it's
associated with any subnets. You can't delete the default network ACL.











=head2 DeleteNetworkAclEntry(Egress => Bool, NetworkAclId => Str, RuleNumber => Int, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DeleteNetworkAclEntry>

Returns: nothing

  

Deletes the specified ingress or egress entry (rule) from the specified
network ACL.











=head2 DeleteNetworkInterface(NetworkInterfaceId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DeleteNetworkInterface>

Returns: nothing

  

Deletes the specified network interface. You must detach the network
interface before you can delete it.











=head2 DeletePlacementGroup(GroupName => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DeletePlacementGroup>

Returns: nothing

  

Deletes the specified placement group. You must terminate all instances
in the placement group before you can delete the placement group. For
more information about placement groups and cluster instances, see
Cluster Instances in the I<Amazon Elastic Compute Cloud User Guide>.











=head2 DeleteRoute(DestinationCidrBlock => Str, RouteTableId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DeleteRoute>

Returns: nothing

  

Deletes the specified route from the specified route table.











=head2 DeleteRouteTable(RouteTableId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DeleteRouteTable>

Returns: nothing

  

Deletes the specified route table. You must disassociate the route
table from any subnets before you can delete it. You can't delete the
main route table.











=head2 DeleteSecurityGroup([DryRun => Bool, GroupId => Str, GroupName => Str])

Each argument is described in detail in: L<Paws::EC2::DeleteSecurityGroup>

Returns: nothing

  

Deletes a security group.

If you attempt to delete a security group that is associated with an
instance, or is referenced by another security group, the operation
fails with C<InvalidGroup.InUse> in EC2-Classic or
C<DependencyViolation> in EC2-VPC.











=head2 DeleteSnapshot(SnapshotId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DeleteSnapshot>

Returns: nothing

  

Deletes the specified snapshot.

When you make periodic snapshots of a volume, the snapshots are
incremental, and only the blocks on the device that have changed since
your last snapshot are saved in the new snapshot. When you delete a
snapshot, only the data not needed for any other snapshot is removed.
So regardless of which prior snapshots have been deleted, all active
snapshots will have access to all the information needed to restore the
volume.

You cannot delete a snapshot of the root device of an EBS volume used
by a registered AMI. You must first de-register the AMI before you can
delete the snapshot.

For more information, see Deleting an Amazon EBS Snapshot in the
I<Amazon Elastic Compute Cloud User Guide>.











=head2 DeleteSpotDatafeedSubscription([DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DeleteSpotDatafeedSubscription>

Returns: nothing

  

Deletes the data feed for Spot Instances. For more information, see
Spot Instance Data Feed in the I<Amazon Elastic Compute Cloud User
Guide>.











=head2 DeleteSubnet(SubnetId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DeleteSubnet>

Returns: nothing

  

Deletes the specified subnet. You must terminate all running instances
in the subnet before you can delete the subnet.











=head2 DeleteTags(Resources => ArrayRef[Str], [DryRun => Bool, Tags => ArrayRef[Paws::EC2::Tag]])

Each argument is described in detail in: L<Paws::EC2::DeleteTags>

Returns: nothing

  

Deletes the specified set of tags from the specified set of resources.
This call is designed to follow a C<DescribeTags> request.

For more information about tags, see Tagging Your Resources in the
I<Amazon Elastic Compute Cloud User Guide>.











=head2 DeleteVolume(VolumeId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DeleteVolume>

Returns: nothing

  

Deletes the specified EBS volume. The volume must be in the
C<available> state (not attached to an instance).

The volume may remain in the C<deleting> state for several minutes.

For more information, see Deleting an Amazon EBS Volume in the I<Amazon
Elastic Compute Cloud User Guide>.











=head2 DeleteVpc(VpcId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DeleteVpc>

Returns: nothing

  

Deletes the specified VPC. You must detach or delete all gateways and
resources that are associated with the VPC before you can delete it.
For example, you must terminate all instances running in the VPC,
delete all security groups associated with the VPC (except the default
one), delete all route tables associated with the VPC (except the
default one), and so on.











=head2 DeleteVpcEndpoints(VpcEndpointIds => ArrayRef[Str], [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DeleteVpcEndpoints>

Returns: a L<Paws::EC2::DeleteVpcEndpointsResult> instance

  

Deletes one or more specified VPC endpoints. Deleting the endpoint also
deletes the endpoint routes in the route tables that were associated
with the endpoint.











=head2 DeleteVpcPeeringConnection(VpcPeeringConnectionId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DeleteVpcPeeringConnection>

Returns: a L<Paws::EC2::DeleteVpcPeeringConnectionResult> instance

  

Deletes a VPC peering connection. Either the owner of the requester VPC
or the owner of the peer VPC can delete the VPC peering connection if
it's in the C<active> state. The owner of the requester VPC can delete
a VPC peering connection in the C<pending-acceptance> state.











=head2 DeleteVpnConnection(VpnConnectionId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DeleteVpnConnection>

Returns: nothing

  

Deletes the specified VPN connection.

If you're deleting the VPC and its associated components, we recommend
that you detach the virtual private gateway from the VPC and delete the
VPC before deleting the VPN connection. If you believe that the tunnel
credentials for your VPN connection have been compromised, you can
delete the VPN connection and create a new one that has new keys,
without needing to delete the VPC or virtual private gateway. If you
create a new VPN connection, you must reconfigure the customer gateway
using the new configuration information returned with the new VPN
connection ID.











=head2 DeleteVpnConnectionRoute(DestinationCidrBlock => Str, VpnConnectionId => Str)

Each argument is described in detail in: L<Paws::EC2::DeleteVpnConnectionRoute>

Returns: nothing

  

Deletes the specified static route associated with a VPN connection
between an existing virtual private gateway and a VPN customer gateway.
The static route allows traffic to be routed from the virtual private
gateway to the VPN customer gateway.











=head2 DeleteVpnGateway(VpnGatewayId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DeleteVpnGateway>

Returns: nothing

  

Deletes the specified virtual private gateway. We recommend that before
you delete a virtual private gateway, you detach it from the VPC and
delete the VPN connection. Note that you don't need to delete the
virtual private gateway if you plan to delete and recreate the VPN
connection between your VPC and your network.











=head2 DeregisterImage(ImageId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DeregisterImage>

Returns: nothing

  

Deregisters the specified AMI. After you deregister an AMI, it can't be
used to launch new instances.

This command does not delete the AMI.











=head2 DescribeAccountAttributes([AttributeNames => ArrayRef[Str], DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DescribeAccountAttributes>

Returns: a L<Paws::EC2::DescribeAccountAttributesResult> instance

  

Describes attributes of your AWS account. The following are the
supported account attributes:

=over

=item *

C<supported-platforms>: Indicates whether your account can launch
instances into EC2-Classic and EC2-VPC, or only into EC2-VPC.

=item *

C<default-vpc>: The ID of the default VPC for your account, or C<none>.

=item *

C<max-instances>: The maximum number of On-Demand instances that you
can run.

=item *

C<vpc-max-security-groups-per-interface>: The maximum number of
security groups that you can assign to a network interface.

=item *

C<max-elastic-ips>: The maximum number of Elastic IP addresses that you
can allocate for use with EC2-Classic.

=item *

C<vpc-max-elastic-ips>: The maximum number of Elastic IP addresses that
you can allocate for use with EC2-VPC.

=back











=head2 DescribeAddresses([AllocationIds => ArrayRef[Str], DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter], PublicIps => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EC2::DescribeAddresses>

Returns: a L<Paws::EC2::DescribeAddressesResult> instance

  

Describes one or more of your Elastic IP addresses.

An Elastic IP address is for use in either the EC2-Classic platform or
in a VPC. For more information, see Elastic IP Addresses in the
I<Amazon Elastic Compute Cloud User Guide>.











=head2 DescribeAvailabilityZones([DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter], ZoneNames => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EC2::DescribeAvailabilityZones>

Returns: a L<Paws::EC2::DescribeAvailabilityZonesResult> instance

  

Describes one or more of the Availability Zones that are available to
you. The results include zones only for the region you're currently
using. If there is an event impacting an Availability Zone, you can use
this request to view the state and any provided message for that
Availability Zone.

For more information, see Regions and Availability Zones in the
I<Amazon Elastic Compute Cloud User Guide>.











=head2 DescribeBundleTasks([BundleIds => ArrayRef[Str], DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter]])

Each argument is described in detail in: L<Paws::EC2::DescribeBundleTasks>

Returns: a L<Paws::EC2::DescribeBundleTasksResult> instance

  

Describes one or more of your bundling tasks.

Completed bundle tasks are listed for only a limited time. If your
bundle task is no longer in the list, you can still register an AMI
from it. Just use C<RegisterImage> with the Amazon S3 bucket name and
image manifest name you provided to the bundle task.











=head2 DescribeClassicLinkInstances([DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter], InstanceIds => ArrayRef[Str], MaxResults => Int, NextToken => Str])

Each argument is described in detail in: L<Paws::EC2::DescribeClassicLinkInstances>

Returns: a L<Paws::EC2::DescribeClassicLinkInstancesResult> instance

  

Describes one or more of your linked EC2-Classic instances. This
request only returns information about EC2-Classic instances linked to
a VPC through ClassicLink; you cannot use this request to return
information about other instances.











=head2 DescribeConversionTasks([ConversionTaskIds => ArrayRef[Str], DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter]])

Each argument is described in detail in: L<Paws::EC2::DescribeConversionTasks>

Returns: a L<Paws::EC2::DescribeConversionTasksResult> instance

  

Describes one or more of your conversion tasks. For more information,
see Using the Command Line Tools to Import Your Virtual Machine to
Amazon EC2 in the I<Amazon Elastic Compute Cloud User Guide>.











=head2 DescribeCustomerGateways([CustomerGatewayIds => ArrayRef[Str], DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter]])

Each argument is described in detail in: L<Paws::EC2::DescribeCustomerGateways>

Returns: a L<Paws::EC2::DescribeCustomerGatewaysResult> instance

  

Describes one or more of your VPN customer gateways.

For more information about VPN customer gateways, see Adding a Hardware
Virtual Private Gateway to Your VPC in the I<Amazon Virtual Private
Cloud User Guide>.











=head2 DescribeDhcpOptions([DhcpOptionsIds => ArrayRef[Str], DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter]])

Each argument is described in detail in: L<Paws::EC2::DescribeDhcpOptions>

Returns: a L<Paws::EC2::DescribeDhcpOptionsResult> instance

  

Describes one or more of your DHCP options sets.

For more information about DHCP options sets, see DHCP Options Sets in
the I<Amazon Virtual Private Cloud User Guide>.











=head2 DescribeExportTasks([ExportTaskIds => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EC2::DescribeExportTasks>

Returns: a L<Paws::EC2::DescribeExportTasksResult> instance

  

Describes one or more of your export tasks.











=head2 DescribeFlowLogs([Filter => ArrayRef[Paws::EC2::Filter], FlowLogIds => ArrayRef[Str], MaxResults => Int, NextToken => Str])

Each argument is described in detail in: L<Paws::EC2::DescribeFlowLogs>

Returns: a L<Paws::EC2::DescribeFlowLogsResult> instance

  

Describes one or more flow logs. To view the information in your flow
logs (the log streams for the network interfaces), you must use the
CloudWatch Logs console or the CloudWatch Logs API.











=head2 DescribeImageAttribute(Attribute => Str, ImageId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DescribeImageAttribute>

Returns: a L<Paws::EC2::ImageAttribute> instance

  

Describes the specified attribute of the specified AMI. You can specify
only one attribute at a time.











=head2 DescribeImages([DryRun => Bool, ExecutableUsers => ArrayRef[Str], Filters => ArrayRef[Paws::EC2::Filter], ImageIds => ArrayRef[Str], Owners => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EC2::DescribeImages>

Returns: a L<Paws::EC2::DescribeImagesResult> instance

  

Describes one or more of the images (AMIs, AKIs, and ARIs) available to
you. Images available to you include public images, private images that
you own, and private images owned by other AWS accounts but for which
you have explicit launch permissions.

Deregistered images are included in the returned results for an
unspecified interval after deregistration.











=head2 DescribeImportImageTasks([DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter], ImportTaskIds => ArrayRef[Str], MaxResults => Int, NextToken => Str])

Each argument is described in detail in: L<Paws::EC2::DescribeImportImageTasks>

Returns: a L<Paws::EC2::DescribeImportImageTasksResult> instance

  

Displays details about an import virtual machine or import snapshot
tasks that are already created.











=head2 DescribeImportSnapshotTasks([DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter], ImportTaskIds => ArrayRef[Str], MaxResults => Int, NextToken => Str])

Each argument is described in detail in: L<Paws::EC2::DescribeImportSnapshotTasks>

Returns: a L<Paws::EC2::DescribeImportSnapshotTasksResult> instance

  

Describes your import snapshot tasks.











=head2 DescribeInstanceAttribute(Attribute => Str, InstanceId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DescribeInstanceAttribute>

Returns: a L<Paws::EC2::InstanceAttribute> instance

  

Describes the specified attribute of the specified instance. You can
specify only one attribute at a time. Valid attribute values are:
C<instanceType> | C<kernel> | C<ramdisk> | C<userData> |
C<disableApiTermination> | C<instanceInitiatedShutdownBehavior> |
C<rootDeviceName> | C<blockDeviceMapping> | C<productCodes> |
C<sourceDestCheck> | C<groupSet> | C<ebsOptimized> | C<sriovNetSupport>











=head2 DescribeInstances([DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter], InstanceIds => ArrayRef[Str], MaxResults => Int, NextToken => Str])

Each argument is described in detail in: L<Paws::EC2::DescribeInstances>

Returns: a L<Paws::EC2::DescribeInstancesResult> instance

  

Describes one or more of your instances.

If you specify one or more instance IDs, Amazon EC2 returns information
for those instances. If you do not specify instance IDs, Amazon EC2
returns information for all relevant instances. If you specify an
instance ID that is not valid, an error is returned. If you specify an
instance that you do not own, it is not included in the returned
results.

Recently terminated instances might appear in the returned results.
This interval is usually less than one hour.











=head2 DescribeInstanceStatus([DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter], IncludeAllInstances => Bool, InstanceIds => ArrayRef[Str], MaxResults => Int, NextToken => Str])

Each argument is described in detail in: L<Paws::EC2::DescribeInstanceStatus>

Returns: a L<Paws::EC2::DescribeInstanceStatusResult> instance

  

Describes the status of one or more instances.

Instance status includes the following components:

=over

=item *

B<Status checks> - Amazon EC2 performs status checks on running EC2
instances to identify hardware and software issues. For more
information, see Status Checks for Your Instances and Troubleshooting
Instances with Failed Status Checks in the I<Amazon Elastic Compute
Cloud User Guide>.

=item *

B<Scheduled events> - Amazon EC2 can schedule events (such as reboot,
stop, or terminate) for your instances related to hardware issues,
software updates, or system maintenance. For more information, see
Scheduled Events for Your Instances in the I<Amazon Elastic Compute
Cloud User Guide>.

=item *

B<Instance state> - You can manage your instances from the moment you
launch them through their termination. For more information, see
Instance Lifecycle in the I<Amazon Elastic Compute Cloud User Guide>.

=back











=head2 DescribeInternetGateways([DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter], InternetGatewayIds => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EC2::DescribeInternetGateways>

Returns: a L<Paws::EC2::DescribeInternetGatewaysResult> instance

  

Describes one or more of your Internet gateways.











=head2 DescribeKeyPairs([DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter], KeyNames => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EC2::DescribeKeyPairs>

Returns: a L<Paws::EC2::DescribeKeyPairsResult> instance

  

Describes one or more of your key pairs.

For more information about key pairs, see Key Pairs in the I<Amazon
Elastic Compute Cloud User Guide>.











=head2 DescribeMovingAddresses([DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter], MaxResults => Int, NextToken => Str, PublicIps => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EC2::DescribeMovingAddresses>

Returns: a L<Paws::EC2::DescribeMovingAddressesResult> instance

  

Describes your Elastic IP addresses that are being moved to the EC2-VPC
platform, or that are being restored to the EC2-Classic platform. This
request does not return information about any other Elastic IP
addresses in your account.











=head2 DescribeNetworkAcls([DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter], NetworkAclIds => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EC2::DescribeNetworkAcls>

Returns: a L<Paws::EC2::DescribeNetworkAclsResult> instance

  

Describes one or more of your network ACLs.

For more information about network ACLs, see Network ACLs in the
I<Amazon Virtual Private Cloud User Guide>.











=head2 DescribeNetworkInterfaceAttribute(NetworkInterfaceId => Str, [Attribute => Str, DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DescribeNetworkInterfaceAttribute>

Returns: a L<Paws::EC2::DescribeNetworkInterfaceAttributeResult> instance

  

Describes a network interface attribute. You can specify only one
attribute at a time.











=head2 DescribeNetworkInterfaces([DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter], NetworkInterfaceIds => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EC2::DescribeNetworkInterfaces>

Returns: a L<Paws::EC2::DescribeNetworkInterfacesResult> instance

  

Describes one or more of your network interfaces.











=head2 DescribePlacementGroups([DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter], GroupNames => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EC2::DescribePlacementGroups>

Returns: a L<Paws::EC2::DescribePlacementGroupsResult> instance

  

Describes one or more of your placement groups. For more information
about placement groups and cluster instances, see Cluster Instances in
the I<Amazon Elastic Compute Cloud User Guide>.











=head2 DescribePrefixLists([DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter], MaxResults => Int, NextToken => Str, PrefixListIds => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EC2::DescribePrefixLists>

Returns: a L<Paws::EC2::DescribePrefixListsResult> instance

  

Describes available AWS services in a prefix list format, which
includes the prefix list name and prefix list ID of the service and the
IP address range for the service. A prefix list ID is required for
creating an outbound security group rule that allows traffic from a VPC
to access an AWS service through a VPC endpoint.











=head2 DescribeRegions([DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter], RegionNames => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EC2::DescribeRegions>

Returns: a L<Paws::EC2::DescribeRegionsResult> instance

  

Describes one or more regions that are currently available to you.

For a list of the regions supported by Amazon EC2, see Regions and
Endpoints.











=head2 DescribeReservedInstances([DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter], OfferingType => Str, ReservedInstancesIds => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EC2::DescribeReservedInstances>

Returns: a L<Paws::EC2::DescribeReservedInstancesResult> instance

  

Describes one or more of the Reserved Instances that you purchased.

For more information about Reserved Instances, see Reserved Instances
in the I<Amazon Elastic Compute Cloud User Guide>.











=head2 DescribeReservedInstancesListings([Filters => ArrayRef[Paws::EC2::Filter], ReservedInstancesId => Str, ReservedInstancesListingId => Str])

Each argument is described in detail in: L<Paws::EC2::DescribeReservedInstancesListings>

Returns: a L<Paws::EC2::DescribeReservedInstancesListingsResult> instance

  

Describes your account's Reserved Instance listings in the Reserved
Instance Marketplace.

The Reserved Instance Marketplace matches sellers who want to resell
Reserved Instance capacity that they no longer need with buyers who
want to purchase additional capacity. Reserved Instances bought and
sold through the Reserved Instance Marketplace work like any other
Reserved Instances.

As a seller, you choose to list some or all of your Reserved Instances,
and you specify the upfront price to receive for them. Your Reserved
Instances are then listed in the Reserved Instance Marketplace and are
available for purchase.

As a buyer, you specify the configuration of the Reserved Instance to
purchase, and the Marketplace matches what you're searching for with
what's available. The Marketplace first sells the lowest priced
Reserved Instances to you, and continues to sell available Reserved
Instance listings to you until your demand is met. You are charged
based on the total price of all of the listings that you purchase.

For more information, see Reserved Instance Marketplace in the I<Amazon
Elastic Compute Cloud User Guide>.











=head2 DescribeReservedInstancesModifications([Filters => ArrayRef[Paws::EC2::Filter], NextToken => Str, ReservedInstancesModificationIds => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EC2::DescribeReservedInstancesModifications>

Returns: a L<Paws::EC2::DescribeReservedInstancesModificationsResult> instance

  

Describes the modifications made to your Reserved Instances. If no
parameter is specified, information about all your Reserved Instances
modification requests is returned. If a modification ID is specified,
only information about the specific modification is returned.

For more information, see Modifying Reserved Instances in the Amazon
Elastic Compute Cloud User Guide.











=head2 DescribeReservedInstancesOfferings([AvailabilityZone => Str, DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter], IncludeMarketplace => Bool, InstanceTenancy => Str, InstanceType => Str, MaxDuration => Int, MaxInstanceCount => Int, MaxResults => Int, MinDuration => Int, NextToken => Str, OfferingType => Str, ProductDescription => Str, ReservedInstancesOfferingIds => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EC2::DescribeReservedInstancesOfferings>

Returns: a L<Paws::EC2::DescribeReservedInstancesOfferingsResult> instance

  

Describes Reserved Instance offerings that are available for purchase.
With Reserved Instances, you purchase the right to launch instances for
a period of time. During that time period, you do not receive
insufficient capacity errors, and you pay a lower usage rate than the
rate charged for On-Demand instances for the actual time used.

For more information, see Reserved Instance Marketplace in the I<Amazon
Elastic Compute Cloud User Guide>.











=head2 DescribeRouteTables([DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter], RouteTableIds => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EC2::DescribeRouteTables>

Returns: a L<Paws::EC2::DescribeRouteTablesResult> instance

  

Describes one or more of your route tables.

For more information about route tables, see Route Tables in the
I<Amazon Virtual Private Cloud User Guide>.











=head2 DescribeSecurityGroups([DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter], GroupIds => ArrayRef[Str], GroupNames => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EC2::DescribeSecurityGroups>

Returns: a L<Paws::EC2::DescribeSecurityGroupsResult> instance

  

Describes one or more of your security groups.

A security group is for use with instances either in the EC2-Classic
platform or in a specific VPC. For more information, see Amazon EC2
Security Groups in the I<Amazon Elastic Compute Cloud User Guide> and
Security Groups for Your VPC in the I<Amazon Virtual Private Cloud User
Guide>.











=head2 DescribeSnapshotAttribute(Attribute => Str, SnapshotId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DescribeSnapshotAttribute>

Returns: a L<Paws::EC2::DescribeSnapshotAttributeResult> instance

  

Describes the specified attribute of the specified snapshot. You can
specify only one attribute at a time.

For more information about EBS snapshots, see Amazon EBS Snapshots in
the I<Amazon Elastic Compute Cloud User Guide>.











=head2 DescribeSnapshots([DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter], MaxResults => Int, NextToken => Str, OwnerIds => ArrayRef[Str], RestorableByUserIds => ArrayRef[Str], SnapshotIds => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EC2::DescribeSnapshots>

Returns: a L<Paws::EC2::DescribeSnapshotsResult> instance

  

Describes one or more of the EBS snapshots available to you. Available
snapshots include public snapshots available for any AWS account to
launch, private snapshots that you own, and private snapshots owned by
another AWS account but for which you've been given explicit create
volume permissions.

The create volume permissions fall into the following categories:

=over

=item * I<public>: The owner of the snapshot granted create volume
permissions for the snapshot to the C<all> group. All AWS accounts have
create volume permissions for these snapshots.

=item * I<explicit>: The owner of the snapshot granted create volume
permissions to a specific AWS account.

=item * I<implicit>: An AWS account has implicit create volume
permissions for all snapshots it owns.

=back

The list of snapshots returned can be modified by specifying snapshot
IDs, snapshot owners, or AWS accounts with create volume permissions.
If no options are specified, Amazon EC2 returns all snapshots for which
you have create volume permissions.

If you specify one or more snapshot IDs, only snapshots that have the
specified IDs are returned. If you specify an invalid snapshot ID, an
error is returned. If you specify a snapshot ID for which you do not
have access, it is not included in the returned results.

If you specify one or more snapshot owners, only snapshots from the
specified owners and for which you have access are returned. The
results can include the AWS account IDs of the specified owners,
C<amazon> for snapshots owned by Amazon, or C<self> for snapshots that
you own.

If you specify a list of restorable users, only snapshots with create
snapshot permissions for those users are returned. You can specify AWS
account IDs (if you own the snapshots), C<self> for snapshots for which
you own or have explicit permissions, or C<all> for public snapshots.

If you are describing a long list of snapshots, you can paginate the
output to make the list more manageable. The C<MaxResults> parameter
sets the maximum number of results returned in a single page. If the
list of results exceeds your C<MaxResults> value, then that number of
results is returned along with a C<NextToken> value that can be passed
to a subsequent C<DescribeSnapshots> request to retrieve the remaining
results.

For more information about EBS snapshots, see Amazon EBS Snapshots in
the I<Amazon Elastic Compute Cloud User Guide>.











=head2 DescribeSpotDatafeedSubscription([DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DescribeSpotDatafeedSubscription>

Returns: a L<Paws::EC2::DescribeSpotDatafeedSubscriptionResult> instance

  

Describes the data feed for Spot Instances. For more information, see
Spot Instance Data Feed in the I<Amazon Elastic Compute Cloud User
Guide>.











=head2 DescribeSpotFleetInstances(SpotFleetRequestId => Str, [DryRun => Bool, MaxResults => Int, NextToken => Str])

Each argument is described in detail in: L<Paws::EC2::DescribeSpotFleetInstances>

Returns: a L<Paws::EC2::DescribeSpotFleetInstancesResponse> instance

  

Describes the running instances for the specified Spot fleet.











=head2 DescribeSpotFleetRequestHistory(SpotFleetRequestId => Str, StartTime => Str, [DryRun => Bool, EventType => Str, MaxResults => Int, NextToken => Str])

Each argument is described in detail in: L<Paws::EC2::DescribeSpotFleetRequestHistory>

Returns: a L<Paws::EC2::DescribeSpotFleetRequestHistoryResponse> instance

  

Describes the events for the specified Spot fleet request during the
specified time.

Spot fleet events are delayed by up to 30 seconds before they can be
described. This ensures that you can query by the last evaluated time
and not miss a recorded event.











=head2 DescribeSpotFleetRequests([DryRun => Bool, MaxResults => Int, NextToken => Str, SpotFleetRequestIds => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EC2::DescribeSpotFleetRequests>

Returns: a L<Paws::EC2::DescribeSpotFleetRequestsResponse> instance

  

Describes your Spot fleet requests.











=head2 DescribeSpotInstanceRequests([DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter], SpotInstanceRequestIds => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EC2::DescribeSpotInstanceRequests>

Returns: a L<Paws::EC2::DescribeSpotInstanceRequestsResult> instance

  

Describes the Spot Instance requests that belong to your account. Spot
Instances are instances that Amazon EC2 launches when the bid price
that you specify exceeds the current Spot Price. Amazon EC2
periodically sets the Spot Price based on available Spot Instance
capacity and current Spot Instance requests. For more information, see
Spot Instance Requests in the I<Amazon Elastic Compute Cloud User
Guide>.

You can use C<DescribeSpotInstanceRequests> to find a running Spot
Instance by examining the response. If the status of the Spot Instance
is C<fulfilled>, the instance ID appears in the response and contains
the identifier of the instance. Alternatively, you can use
DescribeInstances with a filter to look for instances where the
instance lifecycle is C<spot>.











=head2 DescribeSpotPriceHistory([AvailabilityZone => Str, DryRun => Bool, EndTime => Str, Filters => ArrayRef[Paws::EC2::Filter], InstanceTypes => ArrayRef[Str], MaxResults => Int, NextToken => Str, ProductDescriptions => ArrayRef[Str], StartTime => Str])

Each argument is described in detail in: L<Paws::EC2::DescribeSpotPriceHistory>

Returns: a L<Paws::EC2::DescribeSpotPriceHistoryResult> instance

  

Describes the Spot Price history. The prices returned are listed in
chronological order, from the oldest to the most recent, for up to the
past 90 days. For more information, see Spot Instance Pricing History
in the I<Amazon Elastic Compute Cloud User Guide>.

When you specify a start and end time, this operation returns the
prices of the instance types within the time range that you specified
and the time when the price changed. The price is valid within the time
period that you specified; the response merely indicates the last time
that the price changed.











=head2 DescribeSubnets([DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter], SubnetIds => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EC2::DescribeSubnets>

Returns: a L<Paws::EC2::DescribeSubnetsResult> instance

  

Describes one or more of your subnets.

For more information about subnets, see Your VPC and Subnets in the
I<Amazon Virtual Private Cloud User Guide>.











=head2 DescribeTags([DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter], MaxResults => Int, NextToken => Str])

Each argument is described in detail in: L<Paws::EC2::DescribeTags>

Returns: a L<Paws::EC2::DescribeTagsResult> instance

  

Describes one or more of the tags for your EC2 resources.

For more information about tags, see Tagging Your Resources in the
I<Amazon Elastic Compute Cloud User Guide>.











=head2 DescribeVolumeAttribute(VolumeId => Str, [Attribute => Str, DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DescribeVolumeAttribute>

Returns: a L<Paws::EC2::DescribeVolumeAttributeResult> instance

  

Describes the specified attribute of the specified volume. You can
specify only one attribute at a time.

For more information about EBS volumes, see Amazon EBS Volumes in the
I<Amazon Elastic Compute Cloud User Guide>.











=head2 DescribeVolumes([DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter], MaxResults => Int, NextToken => Str, VolumeIds => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EC2::DescribeVolumes>

Returns: a L<Paws::EC2::DescribeVolumesResult> instance

  

Describes the specified EBS volumes.

If you are describing a long list of volumes, you can paginate the
output to make the list more manageable. The C<MaxResults> parameter
sets the maximum number of results returned in a single page. If the
list of results exceeds your C<MaxResults> value, then that number of
results is returned along with a C<NextToken> value that can be passed
to a subsequent C<DescribeVolumes> request to retrieve the remaining
results.

For more information about EBS volumes, see Amazon EBS Volumes in the
I<Amazon Elastic Compute Cloud User Guide>.











=head2 DescribeVolumeStatus([DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter], MaxResults => Int, NextToken => Str, VolumeIds => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EC2::DescribeVolumeStatus>

Returns: a L<Paws::EC2::DescribeVolumeStatusResult> instance

  

Describes the status of the specified volumes. Volume status provides
the result of the checks performed on your volumes to determine events
that can impair the performance of your volumes. The performance of a
volume can be affected if an issue occurs on the volume's underlying
host. If the volume's underlying host experiences a power outage or
system issue, after the system is restored, there could be data
inconsistencies on the volume. Volume events notify you if this occurs.
Volume actions notify you if any action needs to be taken in response
to the event.

The C<DescribeVolumeStatus> operation provides the following
information about the specified volumes:

I<Status>: Reflects the current status of the volume. The possible
values are C<ok>, C<impaired> , C<warning>, or C<insufficient-data>. If
all checks pass, the overall status of the volume is C<ok>. If the
check fails, the overall status is C<impaired>. If the status is
C<insufficient-data>, then the checks may still be taking place on your
volume at the time. We recommend that you retry the request. For more
information on volume status, see Monitoring the Status of Your
Volumes.

I<Events>: Reflect the cause of a volume status and may require you to
take action. For example, if your volume returns an C<impaired> status,
then the volume event might be C<potential-data-inconsistency>. This
means that your volume has been affected by an issue with the
underlying host, has all I/O operations disabled, and may have
inconsistent data.

I<Actions>: Reflect the actions you may have to take in response to an
event. For example, if the status of the volume is C<impaired> and the
volume event shows C<potential-data-inconsistency>, then the action
shows C<enable-volume-io>. This means that you may want to enable the
I/O operations for the volume by calling the EnableVolumeIO action and
then check the volume for data consistency.

Volume status is based on the volume status checks, and does not
reflect the volume state. Therefore, volume status does not indicate
volumes in the C<error> state (for example, when a volume is incapable
of accepting I/O.)











=head2 DescribeVpcAttribute(VpcId => Str, [Attribute => Str, DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DescribeVpcAttribute>

Returns: a L<Paws::EC2::DescribeVpcAttributeResult> instance

  

Describes the specified attribute of the specified VPC. You can specify
only one attribute at a time.











=head2 DescribeVpcClassicLink([DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter], VpcIds => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EC2::DescribeVpcClassicLink>

Returns: a L<Paws::EC2::DescribeVpcClassicLinkResult> instance

  

Describes the ClassicLink status of one or more VPCs.











=head2 DescribeVpcEndpoints([DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter], MaxResults => Int, NextToken => Str, VpcEndpointIds => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EC2::DescribeVpcEndpoints>

Returns: a L<Paws::EC2::DescribeVpcEndpointsResult> instance

  

Describes one or more of your VPC endpoints.











=head2 DescribeVpcEndpointServices([DryRun => Bool, MaxResults => Int, NextToken => Str])

Each argument is described in detail in: L<Paws::EC2::DescribeVpcEndpointServices>

Returns: a L<Paws::EC2::DescribeVpcEndpointServicesResult> instance

  

Describes all supported AWS services that can be specified when
creating a VPC endpoint.











=head2 DescribeVpcPeeringConnections([DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter], VpcPeeringConnectionIds => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EC2::DescribeVpcPeeringConnections>

Returns: a L<Paws::EC2::DescribeVpcPeeringConnectionsResult> instance

  

Describes one or more of your VPC peering connections.











=head2 DescribeVpcs([DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter], VpcIds => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EC2::DescribeVpcs>

Returns: a L<Paws::EC2::DescribeVpcsResult> instance

  

Describes one or more of your VPCs.











=head2 DescribeVpnConnections([DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter], VpnConnectionIds => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EC2::DescribeVpnConnections>

Returns: a L<Paws::EC2::DescribeVpnConnectionsResult> instance

  

Describes one or more of your VPN connections.

For more information about VPN connections, see Adding a Hardware
Virtual Private Gateway to Your VPC in the I<Amazon Virtual Private
Cloud User Guide>.











=head2 DescribeVpnGateways([DryRun => Bool, Filters => ArrayRef[Paws::EC2::Filter], VpnGatewayIds => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EC2::DescribeVpnGateways>

Returns: a L<Paws::EC2::DescribeVpnGatewaysResult> instance

  

Describes one or more of your virtual private gateways.

For more information about virtual private gateways, see Adding an
IPsec Hardware VPN to Your VPC in the I<Amazon Virtual Private Cloud
User Guide>.











=head2 DetachClassicLinkVpc(InstanceId => Str, VpcId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DetachClassicLinkVpc>

Returns: a L<Paws::EC2::DetachClassicLinkVpcResult> instance

  

Unlinks (detaches) a linked EC2-Classic instance from a VPC. After the
instance has been unlinked, the VPC security groups are no longer
associated with it. An instance is automatically unlinked from a VPC
when it's stopped.











=head2 DetachInternetGateway(InternetGatewayId => Str, VpcId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DetachInternetGateway>

Returns: nothing

  

Detaches an Internet gateway from a VPC, disabling connectivity between
the Internet and the VPC. The VPC must not contain any running
instances with Elastic IP addresses.











=head2 DetachNetworkInterface(AttachmentId => Str, [DryRun => Bool, Force => Bool])

Each argument is described in detail in: L<Paws::EC2::DetachNetworkInterface>

Returns: nothing

  

Detaches a network interface from an instance.











=head2 DetachVolume(VolumeId => Str, [Device => Str, DryRun => Bool, Force => Bool, InstanceId => Str])

Each argument is described in detail in: L<Paws::EC2::DetachVolume>

Returns: a L<Paws::EC2::VolumeAttachment> instance

  

Detaches an EBS volume from an instance. Make sure to unmount any file
systems on the device within your operating system before detaching the
volume. Failure to do so results in the volume being stuck in a busy
state while detaching.

If an Amazon EBS volume is the root device of an instance, it can't be
detached while the instance is running. To detach the root volume, stop
the instance first.

When a volume with an AWS Marketplace product code is detached from an
instance, the product code is no longer associated with the instance.

For more information, see Detaching an Amazon EBS Volume in the
I<Amazon Elastic Compute Cloud User Guide>.











=head2 DetachVpnGateway(VpcId => Str, VpnGatewayId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DetachVpnGateway>

Returns: nothing

  

Detaches a virtual private gateway from a VPC. You do this if you're
planning to turn off the VPC and not use it anymore. You can confirm a
virtual private gateway has been completely detached from a VPC by
describing the virtual private gateway (any attachments to the virtual
private gateway are also described).

You must wait for the attachment's state to switch to C<detached>
before you can delete the VPC or attach a different VPC to the virtual
private gateway.











=head2 DisableVgwRoutePropagation(GatewayId => Str, RouteTableId => Str)

Each argument is described in detail in: L<Paws::EC2::DisableVgwRoutePropagation>

Returns: nothing

  

Disables a virtual private gateway (VGW) from propagating routes to a
specified route table of a VPC.











=head2 DisableVpcClassicLink(VpcId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DisableVpcClassicLink>

Returns: a L<Paws::EC2::DisableVpcClassicLinkResult> instance

  

Disables ClassicLink for a VPC. You cannot disable ClassicLink for a
VPC that has EC2-Classic instances linked to it.











=head2 DisassociateAddress([AssociationId => Str, DryRun => Bool, PublicIp => Str])

Each argument is described in detail in: L<Paws::EC2::DisassociateAddress>

Returns: nothing

  

Disassociates an Elastic IP address from the instance or network
interface it's associated with.

An Elastic IP address is for use in either the EC2-Classic platform or
in a VPC. For more information, see Elastic IP Addresses in the
I<Amazon Elastic Compute Cloud User Guide>.

This is an idempotent operation. If you perform the operation more than
once, Amazon EC2 doesn't return an error.











=head2 DisassociateRouteTable(AssociationId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::DisassociateRouteTable>

Returns: nothing

  

Disassociates a subnet from a route table.

After you perform this action, the subnet no longer uses the routes in
the route table. Instead, it uses the routes in the VPC's main route
table. For more information about route tables, see Route Tables in the
I<Amazon Virtual Private Cloud User Guide>.











=head2 EnableVgwRoutePropagation(GatewayId => Str, RouteTableId => Str)

Each argument is described in detail in: L<Paws::EC2::EnableVgwRoutePropagation>

Returns: nothing

  

Enables a virtual private gateway (VGW) to propagate routes to the
specified route table of a VPC.











=head2 EnableVolumeIO(VolumeId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::EnableVolumeIO>

Returns: nothing

  

Enables I/O operations for a volume that had I/O operations disabled
because the data on the volume was potentially inconsistent.











=head2 EnableVpcClassicLink(VpcId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::EnableVpcClassicLink>

Returns: a L<Paws::EC2::EnableVpcClassicLinkResult> instance

  

Enables a VPC for ClassicLink. You can then link EC2-Classic instances
to your ClassicLink-enabled VPC to allow communication over private IP
addresses. You cannot enable your VPC for ClassicLink if any of your
VPC's route tables have existing routes for address ranges within the
C<10.0.0.0/8> IP address range, excluding local routes for VPCs in the
C<10.0.0.0/16> and C<10.1.0.0/16> IP address ranges. For more
information, see ClassicLink in the Amazon Elastic Compute Cloud User
Guide.











=head2 GetConsoleOutput(InstanceId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::GetConsoleOutput>

Returns: a L<Paws::EC2::GetConsoleOutputResult> instance

  

Gets the console output for the specified instance.

Instances do not have a physical monitor through which you can view
their console output. They also lack physical controls that allow you
to power up, reboot, or shut them down. To allow these actions, we
provide them through the Amazon EC2 API and command line interface.

Instance console output is buffered and posted shortly after instance
boot, reboot, and termination. Amazon EC2 preserves the most recent 64
KB output which is available for at least one hour after the most
recent post.

For Linux instances, the instance console output displays the exact
console output that would normally be displayed on a physical monitor
attached to a computer. This output is buffered because the instance
produces it and then posts it to a store where the instance's owner can
retrieve it.

For Windows instances, the instance console output includes output from
the EC2Config service.











=head2 GetPasswordData(InstanceId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::GetPasswordData>

Returns: a L<Paws::EC2::GetPasswordDataResult> instance

  

Retrieves the encrypted administrator password for an instance running
Windows.

The Windows password is generated at boot if the C<EC2Config> service
plugin, C<Ec2SetPassword>, is enabled. This usually only happens the
first time an AMI is launched, and then C<Ec2SetPassword> is
automatically disabled. The password is not generated for rebundled
AMIs unless C<Ec2SetPassword> is enabled before bundling.

The password is encrypted using the key pair that you specified when
you launched the instance. You must provide the corresponding key pair
file.

Password generation and encryption takes a few moments. We recommend
that you wait up to 15 minutes after launching an instance before
trying to retrieve the generated password.











=head2 ImportImage([Architecture => Str, ClientData => Paws::EC2::ClientData, ClientToken => Str, Description => Str, DiskContainers => ArrayRef[Paws::EC2::ImageDiskContainer], DryRun => Bool, Hypervisor => Str, LicenseType => Str, Platform => Str, RoleName => Str])

Each argument is described in detail in: L<Paws::EC2::ImportImage>

Returns: a L<Paws::EC2::ImportImageResult> instance

  

Import single or multi-volume disk images or EBS snapshots into an
Amazon Machine Image (AMI).











=head2 ImportInstance(Platform => Str, [Description => Str, DiskImages => ArrayRef[Paws::EC2::DiskImage], DryRun => Bool, LaunchSpecification => Paws::EC2::ImportInstanceLaunchSpecification])

Each argument is described in detail in: L<Paws::EC2::ImportInstance>

Returns: a L<Paws::EC2::ImportInstanceResult> instance

  

Creates an import instance task using metadata from the specified disk
image. C<ImportInstance> only supports single-volume VMs. To import
multi-volume VMs, use ImportImage. After importing the image, you then
upload it using the C<ec2-import-volume> command in the EC2 command
line tools. For more information, see Using the Command Line Tools to
Import Your Virtual Machine to Amazon EC2 in the I<Amazon Elastic
Compute Cloud User Guide>.











=head2 ImportKeyPair(KeyName => Str, PublicKeyMaterial => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::ImportKeyPair>

Returns: a L<Paws::EC2::ImportKeyPairResult> instance

  

Imports the public key from an RSA key pair that you created with a
third-party tool. Compare this with CreateKeyPair, in which AWS creates
the key pair and gives the keys to you (AWS keeps a copy of the public
key). With ImportKeyPair, you create the key pair and give AWS just the
public key. The private key is never transferred between you and AWS.

For more information about key pairs, see Key Pairs in the I<Amazon
Elastic Compute Cloud User Guide>.











=head2 ImportSnapshot([ClientData => Paws::EC2::ClientData, ClientToken => Str, Description => Str, DiskContainer => Paws::EC2::SnapshotDiskContainer, DryRun => Bool, RoleName => Str])

Each argument is described in detail in: L<Paws::EC2::ImportSnapshot>

Returns: a L<Paws::EC2::ImportSnapshotResult> instance

  

Imports a disk into an EBS snapshot.











=head2 ImportVolume(AvailabilityZone => Str, Image => Paws::EC2::DiskImageDetail, Volume => Paws::EC2::VolumeDetail, [Description => Str, DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::ImportVolume>

Returns: a L<Paws::EC2::ImportVolumeResult> instance

  

Creates an import volume task using metadata from the specified disk
image. After importing the image, you then upload it using the
C<ec2-import-volume> command in the Amazon EC2 command-line interface
(CLI) tools. For more information, see Using the Command Line Tools to
Import Your Virtual Machine to Amazon EC2 in the I<Amazon Elastic
Compute Cloud User Guide>.











=head2 ModifyImageAttribute(ImageId => Str, [Attribute => Str, Description => Paws::EC2::AttributeValue, DryRun => Bool, LaunchPermission => Paws::EC2::LaunchPermissionModifications, OperationType => Str, ProductCodes => ArrayRef[Str], UserGroups => ArrayRef[Str], UserIds => ArrayRef[Str], Value => Str])

Each argument is described in detail in: L<Paws::EC2::ModifyImageAttribute>

Returns: nothing

  

Modifies the specified attribute of the specified AMI. You can specify
only one attribute at a time.

AWS Marketplace product codes cannot be modified. Images with an AWS
Marketplace product code cannot be made public.











=head2 ModifyInstanceAttribute(InstanceId => Str, [Attribute => Str, BlockDeviceMappings => ArrayRef[Paws::EC2::InstanceBlockDeviceMappingSpecification], DisableApiTermination => Paws::EC2::AttributeBooleanValue, DryRun => Bool, EbsOptimized => Paws::EC2::AttributeBooleanValue, Groups => ArrayRef[Str], InstanceInitiatedShutdownBehavior => Paws::EC2::AttributeValue, InstanceType => Paws::EC2::AttributeValue, Kernel => Paws::EC2::AttributeValue, Ramdisk => Paws::EC2::AttributeValue, SourceDestCheck => Paws::EC2::AttributeBooleanValue, SriovNetSupport => Paws::EC2::AttributeValue, UserData => Paws::EC2::BlobAttributeValue, Value => Str])

Each argument is described in detail in: L<Paws::EC2::ModifyInstanceAttribute>

Returns: nothing

  

Modifies the specified attribute of the specified instance. You can
specify only one attribute at a time.

To modify some attributes, the instance must be stopped. For more
information, see Modifying Attributes of a Stopped Instance in the
I<Amazon Elastic Compute Cloud User Guide>.











=head2 ModifyNetworkInterfaceAttribute(NetworkInterfaceId => Str, [Attachment => Paws::EC2::NetworkInterfaceAttachmentChanges, Description => Paws::EC2::AttributeValue, DryRun => Bool, Groups => ArrayRef[Str], SourceDestCheck => Paws::EC2::AttributeBooleanValue])

Each argument is described in detail in: L<Paws::EC2::ModifyNetworkInterfaceAttribute>

Returns: nothing

  

Modifies the specified network interface attribute. You can specify
only one attribute at a time.











=head2 ModifyReservedInstances(ReservedInstancesIds => ArrayRef[Str], TargetConfigurations => ArrayRef[Paws::EC2::ReservedInstancesConfiguration], [ClientToken => Str])

Each argument is described in detail in: L<Paws::EC2::ModifyReservedInstances>

Returns: a L<Paws::EC2::ModifyReservedInstancesResult> instance

  

Modifies the Availability Zone, instance count, instance type, or
network platform (EC2-Classic or EC2-VPC) of your Reserved Instances.
The Reserved Instances to be modified must be identical, except for
Availability Zone, network platform, and instance type.

For more information, see Modifying Reserved Instances in the Amazon
Elastic Compute Cloud User Guide.











=head2 ModifySnapshotAttribute(SnapshotId => Str, [Attribute => Str, CreateVolumePermission => Paws::EC2::CreateVolumePermissionModifications, DryRun => Bool, GroupNames => ArrayRef[Str], OperationType => Str, UserIds => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EC2::ModifySnapshotAttribute>

Returns: nothing

  

Adds or removes permission settings for the specified snapshot. You may
add or remove specified AWS account IDs from a snapshot's list of
create volume permissions, but you cannot do both in a single API call.
If you need to both add and remove account IDs for a snapshot, you must
use multiple API calls.

For more information on modifying snapshot permissions, see Sharing
Snapshots in the I<Amazon Elastic Compute Cloud User Guide>.

Snapshots with AWS Marketplace product codes cannot be made public.











=head2 ModifySubnetAttribute(SubnetId => Str, [MapPublicIpOnLaunch => Paws::EC2::AttributeBooleanValue])

Each argument is described in detail in: L<Paws::EC2::ModifySubnetAttribute>

Returns: nothing

  

Modifies a subnet attribute.











=head2 ModifyVolumeAttribute(VolumeId => Str, [AutoEnableIO => Paws::EC2::AttributeBooleanValue, DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::ModifyVolumeAttribute>

Returns: nothing

  

Modifies a volume attribute.

By default, all I/O operations for the volume are suspended when the
data on the volume is determined to be potentially inconsistent, to
prevent undetectable, latent data corruption. The I/O access to the
volume can be resumed by first enabling I/O access and then checking
the data consistency on your volume.

You can change the default behavior to resume I/O operations. We
recommend that you change this only for boot volumes or for volumes
that are stateless or disposable.











=head2 ModifyVpcAttribute(VpcId => Str, [EnableDnsHostnames => Paws::EC2::AttributeBooleanValue, EnableDnsSupport => Paws::EC2::AttributeBooleanValue])

Each argument is described in detail in: L<Paws::EC2::ModifyVpcAttribute>

Returns: nothing

  

Modifies the specified attribute of the specified VPC.











=head2 ModifyVpcEndpoint(VpcEndpointId => Str, [AddRouteTableIds => ArrayRef[Str], DryRun => Bool, PolicyDocument => Str, RemoveRouteTableIds => ArrayRef[Str], ResetPolicy => Bool])

Each argument is described in detail in: L<Paws::EC2::ModifyVpcEndpoint>

Returns: a L<Paws::EC2::ModifyVpcEndpointResult> instance

  

Modifies attributes of a specified VPC endpoint. You can modify the
policy associated with the endpoint, and you can add and remove route
tables associated with the endpoint.











=head2 MonitorInstances(InstanceIds => ArrayRef[Str], [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::MonitorInstances>

Returns: a L<Paws::EC2::MonitorInstancesResult> instance

  

Enables monitoring for a running instance. For more information about
monitoring instances, see Monitoring Your Instances and Volumes in the
I<Amazon Elastic Compute Cloud User Guide>.











=head2 MoveAddressToVpc(PublicIp => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::MoveAddressToVpc>

Returns: a L<Paws::EC2::MoveAddressToVpcResult> instance

  

Moves an Elastic IP address from the EC2-Classic platform to the
EC2-VPC platform. The Elastic IP address must be allocated to your
account, and it must not be associated with an instance. After the
Elastic IP address is moved, it is no longer available for use in the
EC2-Classic platform, unless you move it back using the
RestoreAddressToClassic request. You cannot move an Elastic IP address
that's allocated for use in the EC2-VPC platform to the EC2-Classic
platform.











=head2 PurchaseReservedInstancesOffering(InstanceCount => Int, ReservedInstancesOfferingId => Str, [DryRun => Bool, LimitPrice => Paws::EC2::ReservedInstanceLimitPrice])

Each argument is described in detail in: L<Paws::EC2::PurchaseReservedInstancesOffering>

Returns: a L<Paws::EC2::PurchaseReservedInstancesOfferingResult> instance

  

Purchases a Reserved Instance for use with your account. With Amazon
EC2 Reserved Instances, you obtain a capacity reservation for a certain
instance configuration over a specified period of time and pay a lower
hourly rate compared to on-Demand Instance pricing.

Use DescribeReservedInstancesOfferings to get a list of Reserved
Instance offerings that match your specifications. After you've
purchased a Reserved Instance, you can check for your new Reserved
Instance with DescribeReservedInstances.

For more information, see Reserved Instances and Reserved Instance
Marketplace in the I<Amazon Elastic Compute Cloud User Guide>.











=head2 RebootInstances(InstanceIds => ArrayRef[Str], [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::RebootInstances>

Returns: nothing

  

Requests a reboot of one or more instances. This operation is
asynchronous; it only queues a request to reboot the specified
instances. The operation succeeds if the instances are valid and belong
to you. Requests to reboot terminated instances are ignored.

If a Linux/Unix instance does not cleanly shut down within four
minutes, Amazon EC2 performs a hard reboot.

For more information about troubleshooting, see Getting Console Output
and Rebooting Instances in the I<Amazon Elastic Compute Cloud User
Guide>.











=head2 RegisterImage(Name => Str, [Architecture => Str, BlockDeviceMappings => ArrayRef[Paws::EC2::BlockDeviceMapping], Description => Str, DryRun => Bool, ImageLocation => Str, KernelId => Str, RamdiskId => Str, RootDeviceName => Str, SriovNetSupport => Str, VirtualizationType => Str])

Each argument is described in detail in: L<Paws::EC2::RegisterImage>

Returns: a L<Paws::EC2::RegisterImageResult> instance

  

Registers an AMI. When you're creating an AMI, this is the final step
you must complete before you can launch an instance from the AMI. For
more information about creating AMIs, see Creating Your Own AMIs in the
I<Amazon Elastic Compute Cloud User Guide>.

For Amazon EBS-backed instances, CreateImage creates and registers the
AMI in a single request, so you don't have to register the AMI
yourself.

You can also use C<RegisterImage> to create an Amazon EBS-backed AMI
from a snapshot of a root device volume. For more information, see
Launching an Instance from a Snapshot in the I<Amazon Elastic Compute
Cloud User Guide>.

If needed, you can deregister an AMI at any time. Any modifications you
make to an AMI backed by an instance store volume invalidates its
registration. If you make changes to an image, deregister the previous
image and register the new image.

You can't register an image where a secondary (non-root) snapshot has
AWS Marketplace product codes.











=head2 RejectVpcPeeringConnection(VpcPeeringConnectionId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::RejectVpcPeeringConnection>

Returns: a L<Paws::EC2::RejectVpcPeeringConnectionResult> instance

  

Rejects a VPC peering connection request. The VPC peering connection
must be in the C<pending-acceptance> state. Use the
DescribeVpcPeeringConnections request to view your outstanding VPC
peering connection requests. To delete an active VPC peering
connection, or to delete a VPC peering connection request that you
initiated, use DeleteVpcPeeringConnection.











=head2 ReleaseAddress([AllocationId => Str, DryRun => Bool, PublicIp => Str])

Each argument is described in detail in: L<Paws::EC2::ReleaseAddress>

Returns: nothing

  

Releases the specified Elastic IP address.

After releasing an Elastic IP address, it is released to the IP address
pool and might be unavailable to you. Be sure to update your DNS
records and any servers or devices that communicate with the address.
If you attempt to release an Elastic IP address that you already
released, you'll get an C<AuthFailure> error if the address is already
allocated to another AWS account.

[EC2-Classic, default VPC] Releasing an Elastic IP address
automatically disassociates it from any instance that it's associated
with. To disassociate an Elastic IP address without releasing it, use
DisassociateAddress.

[Nondefault VPC] You must use DisassociateAddress to disassociate the
Elastic IP address before you try to release it. Otherwise, Amazon EC2
returns an error (C<InvalidIPAddress.InUse>).











=head2 ReplaceNetworkAclAssociation(AssociationId => Str, NetworkAclId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::ReplaceNetworkAclAssociation>

Returns: a L<Paws::EC2::ReplaceNetworkAclAssociationResult> instance

  

Changes which network ACL a subnet is associated with. By default when
you create a subnet, it's automatically associated with the default
network ACL. For more information about network ACLs, see Network ACLs
in the I<Amazon Virtual Private Cloud User Guide>.











=head2 ReplaceNetworkAclEntry(CidrBlock => Str, Egress => Bool, NetworkAclId => Str, Protocol => Str, RuleAction => Str, RuleNumber => Int, [DryRun => Bool, IcmpTypeCode => Paws::EC2::IcmpTypeCode, PortRange => Paws::EC2::PortRange])

Each argument is described in detail in: L<Paws::EC2::ReplaceNetworkAclEntry>

Returns: nothing

  

Replaces an entry (rule) in a network ACL. For more information about
network ACLs, see Network ACLs in the I<Amazon Virtual Private Cloud
User Guide>.











=head2 ReplaceRoute(DestinationCidrBlock => Str, RouteTableId => Str, [DryRun => Bool, GatewayId => Str, InstanceId => Str, NetworkInterfaceId => Str, VpcPeeringConnectionId => Str])

Each argument is described in detail in: L<Paws::EC2::ReplaceRoute>

Returns: nothing

  

Replaces an existing route within a route table in a VPC. You must
provide only one of the following: Internet gateway or virtual private
gateway, NAT instance, VPC peering connection, or network interface.

For more information about route tables, see Route Tables in the
I<Amazon Virtual Private Cloud User Guide>.











=head2 ReplaceRouteTableAssociation(AssociationId => Str, RouteTableId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::ReplaceRouteTableAssociation>

Returns: a L<Paws::EC2::ReplaceRouteTableAssociationResult> instance

  

Changes the route table associated with a given subnet in a VPC. After
the operation completes, the subnet uses the routes in the new route
table it's associated with. For more information about route tables,
see Route Tables in the I<Amazon Virtual Private Cloud User Guide>.

You can also use ReplaceRouteTableAssociation to change which table is
the main route table in the VPC. You just specify the main route
table's association ID and the route table to be the new main route
table.











=head2 ReportInstanceStatus(Instances => ArrayRef[Str], ReasonCodes => ArrayRef[Str], Status => Str, [Description => Str, DryRun => Bool, EndTime => Str, StartTime => Str])

Each argument is described in detail in: L<Paws::EC2::ReportInstanceStatus>

Returns: nothing

  

Submits feedback about the status of an instance. The instance must be
in the C<running> state. If your experience with the instance differs
from the instance status returned by DescribeInstanceStatus, use
ReportInstanceStatus to report your experience with the instance.
Amazon EC2 collects this information to improve the accuracy of status
checks.

Use of this action does not change the value returned by
DescribeInstanceStatus.











=head2 RequestSpotFleet(SpotFleetRequestConfig => Paws::EC2::SpotFleetRequestConfigData, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::RequestSpotFleet>

Returns: a L<Paws::EC2::RequestSpotFleetResponse> instance

  

Creates a Spot fleet request.

For more information, see Spot Fleets in the I<Amazon Elastic Compute
Cloud User Guide>.











=head2 RequestSpotInstances(SpotPrice => Str, [AvailabilityZoneGroup => Str, ClientToken => Str, DryRun => Bool, InstanceCount => Int, LaunchGroup => Str, LaunchSpecification => Paws::EC2::RequestSpotLaunchSpecification, Type => Str, ValidFrom => Str, ValidUntil => Str])

Each argument is described in detail in: L<Paws::EC2::RequestSpotInstances>

Returns: a L<Paws::EC2::RequestSpotInstancesResult> instance

  

Creates a Spot Instance request. Spot Instances are instances that
Amazon EC2 launches when the bid price that you specify exceeds the
current Spot Price. Amazon EC2 periodically sets the Spot Price based
on available Spot Instance capacity and current Spot Instance requests.
For more information, see Spot Instance Requests in the I<Amazon
Elastic Compute Cloud User Guide>.











=head2 ResetImageAttribute(Attribute => Str, ImageId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::ResetImageAttribute>

Returns: nothing

  

Resets an attribute of an AMI to its default value.

The productCodes attribute can't be reset.











=head2 ResetInstanceAttribute(Attribute => Str, InstanceId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::ResetInstanceAttribute>

Returns: nothing

  

Resets an attribute of an instance to its default value. To reset the
C<kernel> or C<ramdisk>, the instance must be in a stopped state. To
reset the C<SourceDestCheck>, the instance can be either running or
stopped.

The C<SourceDestCheck> attribute controls whether source/destination
checking is enabled. The default value is C<true>, which means checking
is enabled. This value must be C<false> for a NAT instance to perform
NAT. For more information, see NAT Instances in the I<Amazon Virtual
Private Cloud User Guide>.











=head2 ResetNetworkInterfaceAttribute(NetworkInterfaceId => Str, [DryRun => Bool, SourceDestCheck => Str])

Each argument is described in detail in: L<Paws::EC2::ResetNetworkInterfaceAttribute>

Returns: nothing

  

Resets a network interface attribute. You can specify only one
attribute at a time.











=head2 ResetSnapshotAttribute(Attribute => Str, SnapshotId => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::ResetSnapshotAttribute>

Returns: nothing

  

Resets permission settings for the specified snapshot.

For more information on modifying snapshot permissions, see Sharing
Snapshots in the I<Amazon Elastic Compute Cloud User Guide>.











=head2 RestoreAddressToClassic(PublicIp => Str, [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::RestoreAddressToClassic>

Returns: a L<Paws::EC2::RestoreAddressToClassicResult> instance

  

Restores an Elastic IP address that was previously moved to the EC2-VPC
platform back to the EC2-Classic platform. You cannot move an Elastic
IP address that was originally allocated for use in EC2-VPC. The
Elastic IP address must not be associated with an instance or network
interface.











=head2 RevokeSecurityGroupEgress(GroupId => Str, [CidrIp => Str, DryRun => Bool, FromPort => Int, IpPermissions => ArrayRef[Paws::EC2::IpPermission], IpProtocol => Str, SourceSecurityGroupName => Str, SourceSecurityGroupOwnerId => Str, ToPort => Int])

Each argument is described in detail in: L<Paws::EC2::RevokeSecurityGroupEgress>

Returns: nothing

  

Removes one or more egress rules from a security group for EC2-VPC. The
values that you specify in the revoke request (for example, ports) must
match the existing rule's values for the rule to be revoked.

Each rule consists of the protocol and the CIDR range or source
security group. For the TCP and UDP protocols, you must also specify
the destination port or range of ports. For the ICMP protocol, you must
also specify the ICMP type and code.

Rule changes are propagated to instances within the security group as
quickly as possible. However, a small delay might occur.











=head2 RevokeSecurityGroupIngress([CidrIp => Str, DryRun => Bool, FromPort => Int, GroupId => Str, GroupName => Str, IpPermissions => ArrayRef[Paws::EC2::IpPermission], IpProtocol => Str, SourceSecurityGroupName => Str, SourceSecurityGroupOwnerId => Str, ToPort => Int])

Each argument is described in detail in: L<Paws::EC2::RevokeSecurityGroupIngress>

Returns: nothing

  

Removes one or more ingress rules from a security group. The values
that you specify in the revoke request (for example, ports) must match
the existing rule's values for the rule to be removed.

Each rule consists of the protocol and the CIDR range or source
security group. For the TCP and UDP protocols, you must also specify
the destination port or range of ports. For the ICMP protocol, you must
also specify the ICMP type and code.

Rule changes are propagated to instances within the security group as
quickly as possible. However, a small delay might occur.











=head2 RunInstances(ImageId => Str, MaxCount => Int, MinCount => Int, [AdditionalInfo => Str, BlockDeviceMappings => ArrayRef[Paws::EC2::BlockDeviceMapping], ClientToken => Str, DisableApiTermination => Bool, DryRun => Bool, EbsOptimized => Bool, IamInstanceProfile => Paws::EC2::IamInstanceProfileSpecification, InstanceInitiatedShutdownBehavior => Str, InstanceType => Str, KernelId => Str, KeyName => Str, Monitoring => Paws::EC2::RunInstancesMonitoringEnabled, NetworkInterfaces => ArrayRef[Paws::EC2::InstanceNetworkInterfaceSpecification], Placement => Paws::EC2::Placement, PrivateIpAddress => Str, RamdiskId => Str, SecurityGroupIds => ArrayRef[Str], SecurityGroups => ArrayRef[Str], SubnetId => Str, UserData => Str])

Each argument is described in detail in: L<Paws::EC2::RunInstances>

Returns: a L<Paws::EC2::Reservation> instance

  

Launches the specified number of instances using an AMI for which you
have permissions.

When you launch an instance, it enters the C<pending> state. After the
instance is ready for you, it enters the C<running> state. To check the
state of your instance, call DescribeInstances.

If you don't specify a security group when launching an instance,
Amazon EC2 uses the default security group. For more information, see
Security Groups in the I<Amazon Elastic Compute Cloud User Guide>.

Linux instances have access to the public key of the key pair at boot.
You can use this key to provide secure access to the instance. Amazon
EC2 public images use this feature to provide secure access without
passwords. For more information, see Key Pairs in the I<Amazon Elastic
Compute Cloud User Guide>.

You can provide optional user data when launching an instance. For more
information, see Instance Metadata in the I<Amazon Elastic Compute
Cloud User Guide>.

If any of the AMIs have a product code attached for which the user has
not subscribed, C<RunInstances> fails.

T2 instance types can only be launched into a VPC. If you do not have a
default VPC, or if you do not specify a subnet ID in the request,
C<RunInstances> fails.

For more information about troubleshooting, see What To Do If An
Instance Immediately Terminates, and Troubleshooting Connecting to Your
Instance in the I<Amazon Elastic Compute Cloud User Guide>.











=head2 StartInstances(InstanceIds => ArrayRef[Str], [AdditionalInfo => Str, DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::StartInstances>

Returns: a L<Paws::EC2::StartInstancesResult> instance

  

Starts an Amazon EBS-backed AMI that you've previously stopped.

Instances that use Amazon EBS volumes as their root devices can be
quickly stopped and started. When an instance is stopped, the compute
resources are released and you are not billed for hourly instance
usage. However, your root partition Amazon EBS volume remains,
continues to persist your data, and you are charged for Amazon EBS
volume usage. You can restart your instance at any time. Each time you
transition an instance from stopped to started, Amazon EC2 charges a
full instance hour, even if transitions happen multiple times within a
single hour.

Before stopping an instance, make sure it is in a state from which it
can be restarted. Stopping an instance does not preserve data stored in
RAM.

Performing this operation on an instance that uses an instance store as
its root device returns an error.

For more information, see Stopping Instances in the I<Amazon Elastic
Compute Cloud User Guide>.











=head2 StopInstances(InstanceIds => ArrayRef[Str], [DryRun => Bool, Force => Bool])

Each argument is described in detail in: L<Paws::EC2::StopInstances>

Returns: a L<Paws::EC2::StopInstancesResult> instance

  

Stops an Amazon EBS-backed instance. Each time you transition an
instance from stopped to started, Amazon EC2 charges a full instance
hour, even if transitions happen multiple times within a single hour.

You can't start or stop Spot Instances.

Instances that use Amazon EBS volumes as their root devices can be
quickly stopped and started. When an instance is stopped, the compute
resources are released and you are not billed for hourly instance
usage. However, your root partition Amazon EBS volume remains,
continues to persist your data, and you are charged for Amazon EBS
volume usage. You can restart your instance at any time.

Before stopping an instance, make sure it is in a state from which it
can be restarted. Stopping an instance does not preserve data stored in
RAM.

Performing this operation on an instance that uses an instance store as
its root device returns an error.

You can stop, start, and terminate EBS-backed instances. You can only
terminate instance store-backed instances. What happens to an instance
differs if you stop it or terminate it. For example, when you stop an
instance, the root device and any other devices attached to the
instance persist. When you terminate an instance, the root device and
any other devices attached during the instance launch are automatically
deleted. For more information about the differences between stopping
and terminating instances, see Instance Lifecycle in the I<Amazon
Elastic Compute Cloud User Guide>.

For more information about troubleshooting, see Troubleshooting
Stopping Your Instance in the I<Amazon Elastic Compute Cloud User
Guide>.











=head2 TerminateInstances(InstanceIds => ArrayRef[Str], [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::TerminateInstances>

Returns: a L<Paws::EC2::TerminateInstancesResult> instance

  

Shuts down one or more instances. This operation is idempotent; if you
terminate an instance more than once, each call succeeds.

Terminated instances remain visible after termination (for
approximately one hour).

By default, Amazon EC2 deletes all EBS volumes that were attached when
the instance launched. Volumes attached after instance launch continue
running.

You can stop, start, and terminate EBS-backed instances. You can only
terminate instance store-backed instances. What happens to an instance
differs if you stop it or terminate it. For example, when you stop an
instance, the root device and any other devices attached to the
instance persist. When you terminate an instance, the root device and
any other devices attached during the instance launch are automatically
deleted. For more information about the differences between stopping
and terminating instances, see Instance Lifecycle in the I<Amazon
Elastic Compute Cloud User Guide>.

For more information about troubleshooting, see Troubleshooting
Terminating Your Instance in the I<Amazon Elastic Compute Cloud User
Guide>.











=head2 UnassignPrivateIpAddresses(NetworkInterfaceId => Str, PrivateIpAddresses => ArrayRef[Str])

Each argument is described in detail in: L<Paws::EC2::UnassignPrivateIpAddresses>

Returns: nothing

  

Unassigns one or more secondary private IP addresses from a network
interface.











=head2 UnmonitorInstances(InstanceIds => ArrayRef[Str], [DryRun => Bool])

Each argument is described in detail in: L<Paws::EC2::UnmonitorInstances>

Returns: a L<Paws::EC2::UnmonitorInstancesResult> instance

  

Disables monitoring for a running instance. For more information about
monitoring instances, see Monitoring Your Instances and Volumes in the
I<Amazon Elastic Compute Cloud User Guide>.











=head1 SEE ALSO

This service class forms part of L<Paws>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

