
package Paws::ECS::ListContainerInstancesResponse {
  use Moose;
  has containerInstanceArns => (is => 'ro', isa => 'ArrayRef[Str]');
  has nextToken => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::ECS::ListContainerInstancesResponse

=head1 ATTRIBUTES

=head2 containerInstanceArns => ArrayRef[Str]

  

The list of container instance full Amazon Resource Name (ARN) entries
for each container instance associated with the specified cluster.









=head2 nextToken => Str

  

The C<nextToken> value to include in a future C<ListContainerInstances>
request. When the results of a C<ListContainerInstances> request exceed
C<maxResults>, this value can be used to retrieve the next page of
results. This value is C<null> when there are no more results to
return.











=cut

1;