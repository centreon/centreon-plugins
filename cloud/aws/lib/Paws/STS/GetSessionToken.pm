
package Paws::STS::GetSessionToken {
  use Moose;
  has DurationSeconds => (is => 'ro', isa => 'Int');
  has SerialNumber => (is => 'ro', isa => 'Str');
  has TokenCode => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'GetSessionToken');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::STS::GetSessionTokenResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'GetSessionTokenResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::STS::GetSessionToken - Arguments for method GetSessionToken on Paws::STS

=head1 DESCRIPTION

This class represents the parameters used for calling the method GetSessionToken on the 
AWS Security Token Service service. Use the attributes of this class
as arguments to method GetSessionToken.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to GetSessionToken.

As an example:

  $service_obj->GetSessionToken(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 DurationSeconds => Int

  

The duration, in seconds, that the credentials should remain valid.
Acceptable durations for IAM user sessions range from 900 seconds (15
minutes) to 129600 seconds (36 hours), with 43200 seconds (12 hours) as
the default. Sessions for AWS account owners are restricted to a
maximum of 3600 seconds (one hour). If the duration is longer than one
hour, the session for AWS account owners defaults to one hour.










=head2 SerialNumber => Str

  

The identification number of the MFA device that is associated with the
IAM user who is making the C<GetSessionToken> call. Specify this value
if the IAM user has a policy that requires MFA authentication. The
value is either the serial number for a hardware device (such as
C<GAHT12345678>) or an Amazon Resource Name (ARN) for a virtual device
(such as C<arn:aws:iam::123456789012:mfa/user>). You can find the
device for an IAM user by going to the AWS Management Console and
viewing the user's security credentials.










=head2 TokenCode => Str

  

The value provided by the MFA device, if MFA is required. If any policy
requires the IAM user to submit an MFA code, specify this value. If MFA
authentication is required, and the user does not provide a code when
requesting a set of temporary security credentials, the user will
receive an "access denied" response when requesting resources that
require MFA authentication.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method GetSessionToken in L<Paws::STS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

