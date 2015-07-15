
package Paws::ECS::ListTasksResponse {
  use Moose;
  has nextToken => (is => 'ro', isa => 'Str');
  has taskArns => (is => 'ro', isa => 'ArrayRef[Str]');

}

### main pod documentation begin ###

=head1 NAME

Paws::ECS::ListTasksResponse

=head1 ATTRIBUTES

=head2 nextToken => Str

  

The C<nextToken> value to include in a future C<ListTasks> request.
When the results of a C<ListTasks> request exceed C<maxResults>, this
value can be used to retrieve the next page of results. This value is
C<null> when there are no more results to return.









=head2 taskArns => ArrayRef[Str]

  

The list of task Amazon Resource Name (ARN) entries for the
C<ListTasks> request.











=cut

1;