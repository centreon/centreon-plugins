
package Paws::IAM::ResyncMFADevice {
  use Moose;
  has AuthenticationCode1 => (is => 'ro', isa => 'Str', required => 1);
  has AuthenticationCode2 => (is => 'ro', isa => 'Str', required => 1);
  has SerialNumber => (is => 'ro', isa => 'Str', required => 1);
  has UserName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ResyncMFADevice');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::ResyncMFADevice - Arguments for method ResyncMFADevice on Paws::IAM

=head1 DESCRIPTION

This class represents the parameters used for calling the method ResyncMFADevice on the 
AWS Identity and Access Management service. Use the attributes of this class
as arguments to method ResyncMFADevice.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ResyncMFADevice.

As an example:

  $service_obj->ResyncMFADevice(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> AuthenticationCode1 => Str

  

An authentication code emitted by the device.










=head2 B<REQUIRED> AuthenticationCode2 => Str

  

A subsequent authentication code emitted by the device.










=head2 B<REQUIRED> SerialNumber => Str

  

Serial number that uniquely identifies the MFA device.










=head2 B<REQUIRED> UserName => Str

  

The name of the user whose MFA device you want to resynchronize.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ResyncMFADevice in L<Paws::IAM>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

