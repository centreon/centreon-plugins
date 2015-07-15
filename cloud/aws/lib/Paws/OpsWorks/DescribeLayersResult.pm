
package Paws::OpsWorks::DescribeLayersResult {
  use Moose;
  has Layers => (is => 'ro', isa => 'ArrayRef[Paws::OpsWorks::Layer]');

}

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::DescribeLayersResult

=head1 ATTRIBUTES

=head2 Layers => ArrayRef[Paws::OpsWorks::Layer]

  

An array of C<Layer> objects that describe the layers.











=cut

1;