package Paws::DS::DirectoryVpcSettingsDescription {
  use Moose;
  has AvailabilityZones => (is => 'ro', isa => 'ArrayRef[Str]');
  has SecurityGroupId => (is => 'ro', isa => 'Str');
  has SubnetIds => (is => 'ro', isa => 'ArrayRef[Str]');
  has VpcId => (is => 'ro', isa => 'Str');
}
1;
