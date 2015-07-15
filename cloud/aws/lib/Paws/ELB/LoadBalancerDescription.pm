package Paws::ELB::LoadBalancerDescription {
  use Moose;
  has AvailabilityZones => (is => 'ro', isa => 'ArrayRef[Str]');
  has BackendServerDescriptions => (is => 'ro', isa => 'ArrayRef[Paws::ELB::BackendServerDescription]');
  has CanonicalHostedZoneName => (is => 'ro', isa => 'Str');
  has CanonicalHostedZoneNameID => (is => 'ro', isa => 'Str');
  has CreatedTime => (is => 'ro', isa => 'Str');
  has DNSName => (is => 'ro', isa => 'Str');
  has HealthCheck => (is => 'ro', isa => 'Paws::ELB::HealthCheck');
  has Instances => (is => 'ro', isa => 'ArrayRef[Paws::ELB::Instance]');
  has ListenerDescriptions => (is => 'ro', isa => 'ArrayRef[Paws::ELB::ListenerDescription]');
  has LoadBalancerName => (is => 'ro', isa => 'Str');
  has Policies => (is => 'ro', isa => 'Paws::ELB::Policies');
  has Scheme => (is => 'ro', isa => 'Str');
  has SecurityGroups => (is => 'ro', isa => 'ArrayRef[Str]');
  has SourceSecurityGroup => (is => 'ro', isa => 'Paws::ELB::SourceSecurityGroup');
  has Subnets => (is => 'ro', isa => 'ArrayRef[Str]');
  has VPCId => (is => 'ro', isa => 'Str');
}
1;
