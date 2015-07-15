
package Paws::EC2::DescribeImportSnapshotTasksResult {
  use Moose;
  has ImportSnapshotTasks => (is => 'ro', isa => 'ArrayRef[Paws::EC2::ImportSnapshotTask]', xmlname => 'importSnapshotTaskSet', traits => ['Unwrapped',]);
  has NextToken => (is => 'ro', isa => 'Str', xmlname => 'nextToken', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeImportSnapshotTasksResult

=head1 ATTRIBUTES

=head2 ImportSnapshotTasks => ArrayRef[Paws::EC2::ImportSnapshotTask]

  

A list of zero or more import snapshot tasks that are currently active
or were completed or canceled in the previous 7 days.









=head2 NextToken => Str

  

The token to use to get the next page of results. This value is C<null>
when there are no more results to return.











=cut

