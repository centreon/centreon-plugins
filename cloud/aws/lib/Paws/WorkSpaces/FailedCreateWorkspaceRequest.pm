package Paws::WorkSpaces::FailedCreateWorkspaceRequest {
  use Moose;
  has ErrorCode => (is => 'ro', isa => 'Str');
  has ErrorMessage => (is => 'ro', isa => 'Str');
  has WorkspaceRequest => (is => 'ro', isa => 'Paws::WorkSpaces::WorkspaceRequest');
}
1;
