package Paws::WorkSpaces::FailedWorkspaceChangeRequest {
  use Moose;
  has ErrorCode => (is => 'ro', isa => 'Str');
  has ErrorMessage => (is => 'ro', isa => 'Str');
  has WorkspaceId => (is => 'ro', isa => 'Str');
}
1;
