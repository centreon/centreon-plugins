package Paws::EMR::Instance {
  use Moose;
  has Ec2InstanceId => (is => 'ro', isa => 'Str');
  has Id => (is => 'ro', isa => 'Str');
  has PrivateDnsName => (is => 'ro', isa => 'Str');
  has PrivateIpAddress => (is => 'ro', isa => 'Str');
  has PublicDnsName => (is => 'ro', isa => 'Str');
  has PublicIpAddress => (is => 'ro', isa => 'Str');
  has Status => (is => 'ro', isa => 'Paws::EMR::InstanceStatus');
}
1;
