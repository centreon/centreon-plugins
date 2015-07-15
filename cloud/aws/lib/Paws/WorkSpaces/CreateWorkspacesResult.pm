
package Paws::WorkSpaces::CreateWorkspacesResult {
  use Moose;
  has FailedRequests => (is => 'ro', isa => 'ArrayRef[Paws::WorkSpaces::FailedCreateWorkspaceRequest]');
  has PendingRequests => (is => 'ro', isa => 'ArrayRef[Paws::WorkSpaces::Workspace]');

}

### main pod documentation begin ###

=head1 NAME

Paws::WorkSpaces::CreateWorkspacesResult

=head1 ATTRIBUTES

=head2 FailedRequests => ArrayRef[Paws::WorkSpaces::FailedCreateWorkspaceRequest]

  

An array of structures that represent the WorkSpaces that could not be
created.









=head2 PendingRequests => ArrayRef[Paws::WorkSpaces::Workspace]

  

An array of structures that represent the WorkSpaces that were created.

Because this operation is asynchronous, the identifier in
C<WorkspaceId> is not immediately available. If you immediately call
DescribeWorkspaces with this identifier, no information will be
returned.











=cut

1;