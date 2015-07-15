
package Paws::MachineLearning::CreateMLModelOutput {
  use Moose;
  has MLModelId => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::MachineLearning::CreateMLModelOutput

=head1 ATTRIBUTES

=head2 MLModelId => Str

  

A user-supplied ID that uniquely identifies the C<MLModel>. This value
should be identical to the value of the C<MLModelId> in the request.











=cut

1;