
package Paws::EC2::DescribeVolumeAttributeResult {
  use Moose;
  has AutoEnableIO => (is => 'ro', isa => 'Paws::EC2::AttributeBooleanValue', xmlname => 'autoEnableIO', traits => ['Unwrapped',]);
  has ProductCodes => (is => 'ro', isa => 'ArrayRef[Paws::EC2::ProductCode]', xmlname => 'productCodes', traits => ['Unwrapped',]);
  has VolumeId => (is => 'ro', isa => 'Str', xmlname => 'volumeId', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeVolumeAttributeResult

=head1 ATTRIBUTES

=head2 AutoEnableIO => Paws::EC2::AttributeBooleanValue

  

The state of C<autoEnableIO> attribute.









=head2 ProductCodes => ArrayRef[Paws::EC2::ProductCode]

  

A list of product codes.









=head2 VolumeId => Str

  

The ID of the volume.











=cut

