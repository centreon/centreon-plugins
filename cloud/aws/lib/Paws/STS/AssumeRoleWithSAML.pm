
package Paws::STS::AssumeRoleWithSAML {
  use Moose;
  has DurationSeconds => (is => 'ro', isa => 'Int');
  has Policy => (is => 'ro', isa => 'Str');
  has PrincipalArn => (is => 'ro', isa => 'Str', required => 1);
  has RoleArn => (is => 'ro', isa => 'Str', required => 1);
  has SAMLAssertion => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'AssumeRoleWithSAML');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::STS::AssumeRoleWithSAMLResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'AssumeRoleWithSAMLResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::STS::AssumeRoleWithSAML - Arguments for method AssumeRoleWithSAML on Paws::STS

=head1 DESCRIPTION

This class represents the parameters used for calling the method AssumeRoleWithSAML on the 
AWS Security Token Service service. Use the attributes of this class
as arguments to method AssumeRoleWithSAML.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to AssumeRoleWithSAML.

As an example:

  $service_obj->AssumeRoleWithSAML(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 DurationSeconds => Int

  

The duration, in seconds, of the role session. The value can range from
900 seconds (15 minutes) to 3600 seconds (1 hour). By default, the
value is set to 3600 seconds. An expiration can also be specified in
the SAML authentication response's C<SessionNotOnOrAfter> value. The
actual expiration time is whichever value is shorter.

The maximum duration for a session is 1 hour, and the minimum duration
is 15 minutes, even if values outside this range are specified.










=head2 Policy => Str

  

An IAM policy in JSON format.

The policy parameter is optional. If you pass a policy, the temporary
security credentials that are returned by the operation have the
permissions that are allowed by both the access policy of the role that
is being assumed, I<B<and>> the policy that you pass. This gives you a
way to further restrict the permissions for the resulting temporary
security credentials. You cannot use the passed policy to grant
permissions that are in excess of those allowed by the access policy of
the role that is being assumed. For more information, see Permissions
for AssumeRoleWithSAML in I<Using Temporary Security Credentials>.

The policy plain text must be 2048 bytes or shorter. However, an
internal conversion compresses it into a packed binary format with a
separate limit. The PackedPolicySize response element indicates by
percentage how close to the upper size limit the policy is, with 100%
equaling the maximum allowed size.










=head2 B<REQUIRED> PrincipalArn => Str

  

The Amazon Resource Name (ARN) of the SAML provider in IAM that
describes the IdP.










=head2 B<REQUIRED> RoleArn => Str

  

The Amazon Resource Name (ARN) of the role that the caller is assuming.










=head2 B<REQUIRED> SAMLAssertion => Str

  

The base-64 encoded SAML authentication response provided by the IdP.

For more information, see Configuring a Relying Party and Adding Claims
in the I<Using IAM> guide.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method AssumeRoleWithSAML in L<Paws::STS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

