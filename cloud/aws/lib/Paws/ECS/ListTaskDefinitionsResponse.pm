
package Paws::ECS::ListTaskDefinitionsResponse {
  use Moose;
  has nextToken => (is => 'ro', isa => 'Str');
  has taskDefinitionArns => (is => 'ro', isa => 'ArrayRef[Str]');

}

### main pod documentation begin ###

=head1 NAME

Paws::ECS::ListTaskDefinitionsResponse

=head1 ATTRIBUTES

=head2 nextToken => Str

  

The C<nextToken> value to include in a future C<ListTaskDefinitions>
request. When the results of a C<ListTaskDefinitions> request exceed
C<maxResults>, this value can be used to retrieve the next page of
results. This value is C<null> when there are no more results to
return.









=head2 taskDefinitionArns => ArrayRef[Str]

  

The list of task definition Amazon Resource Name (ARN) entries for the
C<ListTaskDefintions> request.











=cut

1;