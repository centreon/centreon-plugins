
package Paws::ECS::ListClustersResponse {
  use Moose;
  has clusterArns => (is => 'ro', isa => 'ArrayRef[Str]');
  has nextToken => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::ECS::ListClustersResponse

=head1 ATTRIBUTES

=head2 clusterArns => ArrayRef[Str]

  

The list of full Amazon Resource Name (ARN) entries for each cluster
associated with your account.









=head2 nextToken => Str

  

The C<nextToken> value to include in a future C<ListClusters> request.
When the results of a C<ListClusters> request exceed C<maxResults>,
this value can be used to retrieve the next page of results. This value
is C<null> when there are no more results to return.











=cut

1;