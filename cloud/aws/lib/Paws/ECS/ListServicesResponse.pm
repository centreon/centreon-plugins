
package Paws::ECS::ListServicesResponse {
  use Moose;
  has nextToken => (is => 'ro', isa => 'Str');
  has serviceArns => (is => 'ro', isa => 'ArrayRef[Str]');

}

### main pod documentation begin ###

=head1 NAME

Paws::ECS::ListServicesResponse

=head1 ATTRIBUTES

=head2 nextToken => Str

  

The C<nextToken> value to include in a future C<ListServices> request.
When the results of a C<ListServices> request exceed C<maxResults>,
this value can be used to retrieve the next page of results. This value
is C<null> when there are no more results to return.









=head2 serviceArns => ArrayRef[Str]

  

The list of full Amazon Resource Name (ARN) entries for each service
associated with the specified cluster.











=cut

1;