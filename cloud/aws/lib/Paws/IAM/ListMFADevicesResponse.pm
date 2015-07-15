
package Paws::IAM::ListMFADevicesResponse {
  use Moose;
  has IsTruncated => (is => 'ro', isa => 'Bool');
  has Marker => (is => 'ro', isa => 'Str');
  has MFADevices => (is => 'ro', isa => 'ArrayRef[Paws::IAM::MFADevice]', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::ListMFADevicesResponse

=head1 ATTRIBUTES

=head2 IsTruncated => Bool

  

A flag that indicates whether there are more MFA devices to list. If
your results were truncated, you can make a subsequent pagination
request using the C<Marker> request parameter to retrieve more MFA
devices in the list.









=head2 Marker => Str

  

If C<IsTruncated> is C<true>, this element is present and contains the
value to use for the C<Marker> parameter in a subsequent pagination
request.









=head2 B<REQUIRED> MFADevices => ArrayRef[Paws::IAM::MFADevice]

  

A list of MFA devices.











=cut

