
package Paws::StorageGateway::DescribeUploadBufferOutput {
  use Moose;
  has DiskIds => (is => 'ro', isa => 'ArrayRef[Str]');
  has GatewayARN => (is => 'ro', isa => 'Str');
  has UploadBufferAllocatedInBytes => (is => 'ro', isa => 'Int');
  has UploadBufferUsedInBytes => (is => 'ro', isa => 'Int');

}

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::DescribeUploadBufferOutput

=head1 ATTRIBUTES

=head2 DiskIds => ArrayRef[Str]

  
=head2 GatewayARN => Str

  
=head2 UploadBufferAllocatedInBytes => Int

  
=head2 UploadBufferUsedInBytes => Int

  


=cut

1;