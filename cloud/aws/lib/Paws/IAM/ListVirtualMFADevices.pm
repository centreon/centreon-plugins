
package Paws::IAM::ListVirtualMFADevices {
  use Moose;
  has AssignmentStatus => (is => 'ro', isa => 'Str');
  has Marker => (is => 'ro', isa => 'Str');
  has MaxItems => (is => 'ro', isa => 'Int');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListVirtualMFADevices');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::IAM::ListVirtualMFADevicesResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ListVirtualMFADevicesResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::ListVirtualMFADevices - Arguments for method ListVirtualMFADevices on Paws::IAM

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListVirtualMFADevices on the 
AWS Identity and Access Management service. Use the attributes of this class
as arguments to method ListVirtualMFADevices.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListVirtualMFADevices.

As an example:

  $service_obj->ListVirtualMFADevices(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AssignmentStatus => Str

  

The status (unassigned or assigned) of the devices to list. If you do
not specify an C<AssignmentStatus>, the action defaults to C<Any> which
lists both assigned and unassigned virtual MFA devices.










=head2 Marker => Str

  

Use this parameter only when paginating results, and only in a
subsequent request after you've received a response where the results
are truncated. Set it to the value of the C<Marker> element in the
response you just received.










=head2 MaxItems => Int

  

Use this parameter only when paginating results to indicate the maximum
number of MFA devices you want in the response. If there are additional
MFA devices beyond the maximum you specify, the C<IsTruncated> response
element is C<true>. This parameter is optional. If you do not include
it, it defaults to 100.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListVirtualMFADevices in L<Paws::IAM>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

