package Paws::WorkSpaces::RebuildRequest {
  use Moose;
  has WorkspaceId => (is => 'ro', isa => 'Str', required => 1);
}
1;
