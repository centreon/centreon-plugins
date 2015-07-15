
package Paws::MachineLearning::UpdateMLModelOutput {
  use Moose;
  has MLModelId => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::MachineLearning::UpdateMLModelOutput

=head1 ATTRIBUTES

=head2 MLModelId => Str

  

The ID assigned to the C<MLModel> during creation. This value should be
identical to the value of the C<MLModelID> in the request.











=cut

1;