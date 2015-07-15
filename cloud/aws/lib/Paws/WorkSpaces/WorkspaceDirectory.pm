package Paws::WorkSpaces::WorkspaceDirectory {
  use Moose;
  has Alias => (is => 'ro', isa => 'Str');
  has CustomerUserName => (is => 'ro', isa => 'Str');
  has DirectoryId => (is => 'ro', isa => 'Str');
  has DirectoryName => (is => 'ro', isa => 'Str');
  has DirectoryType => (is => 'ro', isa => 'Str');
  has DnsIpAddresses => (is => 'ro', isa => 'ArrayRef[Str]');
  has IamRoleId => (is => 'ro', isa => 'Str');
  has RegistrationCode => (is => 'ro', isa => 'Str');
  has State => (is => 'ro', isa => 'Str');
  has SubnetIds => (is => 'ro', isa => 'ArrayRef[Str]');
  has WorkspaceCreationProperties => (is => 'ro', isa => 'Paws::WorkSpaces::DefaultWorkspaceCreationProperties');
  has WorkspaceSecurityGroupId => (is => 'ro', isa => 'Str');
}
1;
