package Paws::WorkSpaces::WorkspaceBundle {
  use Moose;
  has BundleId => (is => 'ro', isa => 'Str');
  has ComputeType => (is => 'ro', isa => 'Paws::WorkSpaces::ComputeType');
  has Description => (is => 'ro', isa => 'Str');
  has Name => (is => 'ro', isa => 'Str');
  has Owner => (is => 'ro', isa => 'Str');
  has UserStorage => (is => 'ro', isa => 'Paws::WorkSpaces::UserStorage');
}
1;
