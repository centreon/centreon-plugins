
package Paws::STS::AssumeRoleWithWebIdentity {
  use Moose;
  has DurationSeconds => (is => 'ro', isa => 'Int');
  has Policy => (is => 'ro', isa => 'Str');
  has ProviderId => (is => 'ro', isa => 'Str');
  has RoleArn => (is => 'ro', isa => 'Str', required => 1);
  has RoleSessionName => (is => 'ro', isa => 'Str', required => 1);
  has WebIdentityToken => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'AssumeRoleWithWebIdentity');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::STS::AssumeRoleWithWebIdentityResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'AssumeRoleWithWebIdentityResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::STS::AssumeRoleWithWebIdentity - Arguments for method AssumeRoleWithWebIdentity on Paws::STS

=head1 DESCRIPTION

This class represents the parameters used for calling the method AssumeRoleWithWebIdentity on the 
AWS Security Token Service service. Use the attributes of this class
as arguments to method AssumeRoleWithWebIdentity.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to AssumeRoleWithWebIdentity.

As an example:

  $service_obj->AssumeRoleWithWebIdentity(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 DurationSeconds => Int

  

The duration, in seconds, of the role session. The value can range from
900 seconds (15 minutes) to 3600 seconds (1 hour). By default, the
value is set to 3600 seconds.










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
for AssumeRoleWithWebIdentity.

The policy plain text must be 2048 bytes or shorter. However, an
internal conversion compresses it into a packed binary format with a
separate limit. The PackedPolicySize response element indicates by
percentage how close to the upper size limit the policy is, with 100%
equaling the maximum allowed size.










=head2 ProviderId => Str

  

The fully qualified host component of the domain name of the identity
provider.

Specify this value only for OAuth 2.0 access tokens. Currently
C<www.amazon.com> and C<graph.facebook.com> are the only supported
identity providers for OAuth 2.0 access tokens. Do not include URL
schemes and port numbers.

Do not specify this value for OpenID Connect ID tokens.










=head2 B<REQUIRED> RoleArn => Str

  

The Amazon Resource Name (ARN) of the role that the caller is assuming.










=head2 B<REQUIRED> RoleSessionName => Str

  

An identifier for the assumed role session. Typically, you pass the
name or identifier that is associated with the user who is using your
application. That way, the temporary security credentials that your
application will use are associated with that user. This session name
is included as part of the ARN and assumed role ID in the
C<AssumedRoleUser> response element.










=head2 B<REQUIRED> WebIdentityToken => Str

  

The OAuth 2.0 access token or OpenID Connect ID token that is provided
by the identity provider. Your application must get this token by
authenticating the user who is using your application with a web
identity provider before the application makes an
C<AssumeRoleWithWebIdentity> call.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method AssumeRoleWithWebIdentity in L<Paws::STS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

