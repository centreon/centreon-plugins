package Paws::DS::DirectoryConnectSettingsDescription {
  use Moose;
  has AvailabilityZones => (is => 'ro', isa => 'ArrayRef[Str]');
  has ConnectIps => (is => 'ro', isa => 'ArrayRef[Str]');
  has CustomerUserName => (is => 'ro', isa => 'Str');
  has SecurityGroupId => (is => 'ro', isa => 'Str');
  has SubnetIds => (is => 'ro', isa => 'ArrayRef[Str]');
  has VpcId => (is => 'ro', isa => 'Str');
}
1;
