
package Paws::MachineLearning::DeleteRealtimeEndpointOutput {
  use Moose;
  has MLModelId => (is => 'ro', isa => 'Str');
  has RealtimeEndpointInfo => (is => 'ro', isa => 'Paws::MachineLearning::RealtimeEndpointInfo');

}

### main pod documentation begin ###

=head1 NAME

Paws::MachineLearning::DeleteRealtimeEndpointOutput

=head1 ATTRIBUTES

=head2 MLModelId => Str

  

A user-supplied ID that uniquely identifies the C<MLModel>. This value
should be identical to the value of the C<MLModelId> in the request.









=head2 RealtimeEndpointInfo => Paws::MachineLearning::RealtimeEndpointInfo

  

The endpoint information of the C<MLModel>











=cut

1;