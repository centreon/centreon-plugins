
package Paws::EC2::AttachNetworkInterfaceResult {
  use Moose;
  has AttachmentId => (is => 'ro', isa => 'Str', xmlname => 'attachmentId', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::AttachNetworkInterfaceResult

=head1 ATTRIBUTES

=head2 AttachmentId => Str

  

The ID of the network interface attachment.











=cut

