
package Paws::IAM::CreateVirtualMFADeviceResponse {
  use Moose;
  has VirtualMFADevice => (is => 'ro', isa => 'Paws::IAM::VirtualMFADevice', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::CreateVirtualMFADeviceResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> VirtualMFADevice => Paws::IAM::VirtualMFADevice

  

A newly created virtual MFA device.











=cut

