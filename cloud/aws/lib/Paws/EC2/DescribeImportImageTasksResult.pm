
package Paws::EC2::DescribeImportImageTasksResult {
  use Moose;
  has ImportImageTasks => (is => 'ro', isa => 'ArrayRef[Paws::EC2::ImportImageTask]', xmlname => 'importImageTaskSet', traits => ['Unwrapped',]);
  has NextToken => (is => 'ro', isa => 'Str', xmlname => 'nextToken', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeImportImageTasksResult

=head1 ATTRIBUTES

=head2 ImportImageTasks => ArrayRef[Paws::EC2::ImportImageTask]

  

A list of zero or more import image tasks that are currently active or
were completed or canceled in the previous 7 days.









=head2 NextToken => Str

  

The token to use to get the next page of results. This value is C<null>
when there are no more results to return.











=cut

