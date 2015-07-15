package Paws::EMR::Ec2InstanceAttributes {
  use Moose;
  has AdditionalMasterSecurityGroups => (is => 'ro', isa => 'ArrayRef[Str]');
  has AdditionalSlaveSecurityGroups => (is => 'ro', isa => 'ArrayRef[Str]');
  has Ec2AvailabilityZone => (is => 'ro', isa => 'Str');
  has Ec2KeyName => (is => 'ro', isa => 'Str');
  has Ec2SubnetId => (is => 'ro', isa => 'Str');
  has EmrManagedMasterSecurityGroup => (is => 'ro', isa => 'Str');
  has EmrManagedSlaveSecurityGroup => (is => 'ro', isa => 'Str');
  has IamInstanceProfile => (is => 'ro', isa => 'Str');
}
1;
