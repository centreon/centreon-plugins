package Paws::WorkSpaces::Workspace {
  use Moose;
  has BundleId => (is => 'ro', isa => 'Str');
  has DirectoryId => (is => 'ro', isa => 'Str');
  has ErrorCode => (is => 'ro', isa => 'Str');
  has ErrorMessage => (is => 'ro', isa => 'Str');
  has IpAddress => (is => 'ro', isa => 'Str');
  has State => (is => 'ro', isa => 'Str');
  has SubnetId => (is => 'ro', isa => 'Str');
  has UserName => (is => 'ro', isa => 'Str');
  has WorkspaceId => (is => 'ro', isa => 'Str');
}
1;
