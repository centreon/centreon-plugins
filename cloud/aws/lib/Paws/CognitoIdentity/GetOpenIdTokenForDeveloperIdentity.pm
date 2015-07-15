
package Paws::CognitoIdentity::GetOpenIdTokenForDeveloperIdentity {
  use Moose;
  has IdentityId => (is => 'ro', isa => 'Str');
  has IdentityPoolId => (is => 'ro', isa => 'Str', required => 1);
  has Logins => (is => 'ro', isa => 'Paws::CognitoIdentity::LoginsMap', required => 1);
  has TokenDuration => (is => 'ro', isa => 'Int');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'GetOpenIdTokenForDeveloperIdentity');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CognitoIdentity::GetOpenIdTokenForDeveloperIdentityResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CognitoIdentity::GetOpenIdTokenForDeveloperIdentity - Arguments for method GetOpenIdTokenForDeveloperIdentity on Paws::CognitoIdentity

=head1 DESCRIPTION

This class represents the parameters used for calling the method GetOpenIdTokenForDeveloperIdentity on the 
Amazon Cognito Identity service. Use the attributes of this class
as arguments to method GetOpenIdTokenForDeveloperIdentity.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to GetOpenIdTokenForDeveloperIdentity.

As an example:

  $service_obj->GetOpenIdTokenForDeveloperIdentity(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 IdentityId => Str

  

A unique identifier in the format REGION:GUID.










=head2 B<REQUIRED> IdentityPoolId => Str

  

An identity pool ID in the format REGION:GUID.










=head2 B<REQUIRED> Logins => Paws::CognitoIdentity::LoginsMap

  

A set of optional name-value pairs that map provider names to provider
tokens. Each name-value pair represents a user from a public provider
or developer provider. If the user is from a developer provider, the
name-value pair will follow the syntax C<"developer_provider_name":
"developer_user_identifier">. The developer provider is the "domain" by
which Cognito will refer to your users; you provided this domain while
creating/updating the identity pool. The developer user identifier is
an identifier from your backend that uniquely identifies a user. When
you create an identity pool, you can specify the supported logins.










=head2 TokenDuration => Int

  

The expiration time of the token, in seconds. You can specify a custom
expiration time for the token so that you can cache it. If you don't
provide an expiration time, the token is valid for 15 minutes. You can
exchange the token with Amazon STS for temporary AWS credentials, which
are valid for a maximum of one hour. The maximum token duration you can
set is 24 hours. You should take care in setting the expiration time
for a token, as there are significant security implications: an
attacker could use a leaked token to access your AWS resources for the
token's duration.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method GetOpenIdTokenForDeveloperIdentity in L<Paws::CognitoIdentity>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

