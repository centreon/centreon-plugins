
package Paws::CodePipeline::ListActionTypesOutput {
  use Moose;
  has actionTypes => (is => 'ro', isa => 'ArrayRef[Paws::CodePipeline::ActionType]', required => 1);
  has nextToken => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::CodePipeline::ListActionTypesOutput

=head1 ATTRIBUTES

=head2 B<REQUIRED> actionTypes => ArrayRef[Paws::CodePipeline::ActionType]

  

Provides details of the action types.









=head2 nextToken => Str

  

If the amount of returned information is significantly large, an
identifier is also returned which can be used in a subsequent list
action types call to return the next set of action types in the list.











=cut

1;