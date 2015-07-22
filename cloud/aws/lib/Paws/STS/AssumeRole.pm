
package Paws::STS::AssumeRole {
  use Moose;
  has DurationSeconds => (is => 'ro', isa => 'Int');
  has ExternalId => (is => 'ro', isa => 'Str');
  has Policy => (is => 'ro', isa => 'Str');
  has RoleArn => (is => 'ro', isa => 'Str', required => 1);
  has RoleSessionName => (is => 'ro', isa => 'Str', required => 1);
  has SerialNumber => (is => 'ro', isa => 'Str');
  has TokenCode => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'AssumeRole');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::STS::AssumeRoleResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'AssumeRoleResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::STS::AssumeRole - Arguments for method AssumeRole on Paws::STS

=head1 DESCRIPTION

This class represents the parameters used for calling the method AssumeRole on the 
AWS Security Token Service service. Use the attributes of this class
as arguments to method AssumeRole.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to AssumeRole.

As an example:

  $service_obj->AssumeRole(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 DurationSeconds => Int

  

The duration, in seconds, of the role session. The value can range from
900 seconds (15 minutes) to 3600 seconds (1 hour). By default, the
value is set to 3600 seconds.










=head2 ExternalId => Str

  

A unique identifier that is used by third parties when assuming roles
in their customers' accounts. For each role that the third party can
assume, they should instruct their customers to ensure the role's trust
policy checks for the external ID that the third party generated. Each
time the third party assumes the role, they should pass the customer's
external ID. The external ID is useful in order to help third parties
bind a role to the customer who created it. For more information about
the external ID, see How to Use External ID When Granting Access to
Your AWS Resources in I<Using Temporary Security Credentials>.










=head2 Policy => Str

  

An IAM policy in JSON format.

This parameter is optional. If you pass a policy, the temporary
security credentials that are returned by the operation have the
permissions that are allowed by both (the intersection of) the access
policy of the role that is being assumed, I<and> the policy that you
pass. This gives you a way to further restrict the permissions for the
resulting temporary security credentials. You cannot use the passed
policy to grant permissions that are in excess of those allowed by the
access policy of the role that is being assumed. For more information,
see Permissions for AssumeRole, AssumeRoleWithSAML, and
AssumeRoleWithWebIdentity in I<Using Temporary Security Credentials>.

The policy plain text must be 2048 bytes or shorter. However, an
internal conversion compresses it into a packed binary format with a
separate limit. The PackedPolicySize response element indicates by
percentage how close to the upper size limit the policy is, with 100%
equaling the maximum allowed size.










=head2 B<REQUIRED> RoleArn => Str

  

The Amazon Resource Name (ARN) of the role to assume.










=head2 B<REQUIRED> RoleSessionName => Str

  

An identifier for the assumed role session.

Use the role session name to uniquely identity a session when the same
role is assumed by different principals or for different reasons. In
cross-account scenarios, the role session name is visible to, and can
be logged by the account that owns the role. The role session name is
also used in the ARN of the assumed role principal. This means that
subsequent cross-account API requests using the temporary security
credentials will expose the role session name to the external account
in their CloudTrail logs.










=head2 SerialNumber => Str

  

The identification number of the MFA device that is associated with the
user who is making the C<AssumeRole> call. Specify this value if the
trust policy of the role being assumed includes a condition that
requires MFA authentication. The value is either the serial number for
a hardware device (such as C<GAHT12345678>) or an Amazon Resource Name
(ARN) for a virtual device (such as
C<arn:aws:iam::123456789012:mfa/user>).










=head2 TokenCode => Str

  

The value provided by the MFA device, if the trust policy of the role
being assumed requires MFA (that is, if the policy includes a condition
that tests for MFA). If the role being assumed requires MFA and if the
C<TokenCode> value is missing or expired, the C<AssumeRole> call
returns an "access denied" error.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method AssumeRole in L<Paws::STS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

