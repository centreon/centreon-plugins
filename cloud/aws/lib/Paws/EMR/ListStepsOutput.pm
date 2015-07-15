
package Paws::EMR::ListStepsOutput {
  use Moose;
  has Marker => (is => 'ro', isa => 'Str');
  has Steps => (is => 'ro', isa => 'ArrayRef[Paws::EMR::StepSummary]');

}

### main pod documentation begin ###

=head1 NAME

Paws::EMR::ListStepsOutput

=head1 ATTRIBUTES

=head2 Marker => Str

  

The pagination token that indicates the next set of results to
retrieve.









=head2 Steps => ArrayRef[Paws::EMR::StepSummary]

  

The filtered list of steps for the cluster.











=cut

1;