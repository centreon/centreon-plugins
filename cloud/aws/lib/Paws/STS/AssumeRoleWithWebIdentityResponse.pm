
package Paws::STS::AssumeRoleWithWebIdentityResponse {
  use Moose;
  has AssumedRoleUser => (is => 'ro', isa => 'Paws::STS::AssumedRoleUser');
  has Audience => (is => 'ro', isa => 'Str');
  has Credentials => (is => 'ro', isa => 'Paws::STS::Credentials');
  has PackedPolicySize => (is => 'ro', isa => 'Int');
  has Provider => (is => 'ro', isa => 'Str');
  has SubjectFromWebIdentityToken => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::STS::AssumeRoleWithWebIdentityResponse

=head1 ATTRIBUTES

=head2 AssumedRoleUser => Paws::STS::AssumedRoleUser

  

The Amazon Resource Name (ARN) and the assumed role ID, which are
identifiers that you can use to refer to the resulting temporary
security credentials. For example, you can reference these credentials
as a principal in a resource-based policy by using the ARN or assumed
role ID. The ARN and ID include the C<RoleSessionName> that you
specified when you called C<AssumeRole>.









=head2 Audience => Str

  

The intended audience (also known as client ID) of the web identity
token. This is traditionally the client identifier issued to the
application that requested the web identity token.









=head2 Credentials => Paws::STS::Credentials

  

The temporary security credentials, which include an access key ID, a
secret access key, and a security token.









=head2 PackedPolicySize => Int

  

A percentage value that indicates the size of the policy in packed
form. The service rejects any policy with a packed size greater than
100 percent, which means the policy exceeded the allowed space.









=head2 Provider => Str

  

The issuing authority of the web identity token presented. For OpenID
Connect ID Tokens this contains the value of the C<iss> field. For
OAuth 2.0 access tokens, this contains the value of the C<ProviderId>
parameter that was passed in the C<AssumeRoleWithWebIdentity> request.









=head2 SubjectFromWebIdentityToken => Str

  

The unique user identifier that is returned by the identity provider.
This identifier is associated with the C<WebIdentityToken> that was
submitted with the C<AssumeRoleWithWebIdentity> call. The identifier is
typically unique to the user and the application that acquired the
C<WebIdentityToken> (pairwise identifier). For OpenID Connect ID
tokens, this field contains the value returned by the identity provider
as the token's C<sub> (Subject) claim.











=cut

