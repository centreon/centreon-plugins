
package Paws::MachineLearning::DeleteEvaluationOutput {
  use Moose;
  has EvaluationId => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::MachineLearning::DeleteEvaluationOutput

=head1 ATTRIBUTES

=head2 EvaluationId => Str

  

A user-supplied ID that uniquely identifies the C<Evaluation>. This
value should be identical to the value of the C<EvaluationId> in the
request.











=cut

1;