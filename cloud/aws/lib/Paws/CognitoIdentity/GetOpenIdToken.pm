
package Paws::CognitoIdentity::GetOpenIdToken {
  use Moose;
  has IdentityId => (is => 'ro', isa => 'Str', required => 1);
  has Logins => (is => 'ro', isa => 'Paws::CognitoIdentity::LoginsMap');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'GetOpenIdToken');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CognitoIdentity::GetOpenIdTokenResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CognitoIdentity::GetOpenIdToken - Arguments for method GetOpenIdToken on Paws::CognitoIdentity

=head1 DESCRIPTION

This class represents the parameters used for calling the method GetOpenIdToken on the 
Amazon Cognito Identity service. Use the attributes of this class
as arguments to method GetOpenIdToken.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to GetOpenIdToken.

As an example:

  $service_obj->GetOpenIdToken(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> IdentityId => Str

  

A unique identifier in the format REGION:GUID.










=head2 Logins => Paws::CognitoIdentity::LoginsMap

  

A set of optional name-value pairs that map provider names to provider
tokens. When using graph.facebook.com and www.amazon.com, supply the
access_token returned from the provider's authflow. For
accounts.google.com or any other OpenId Connect provider, always
include the id_token.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method GetOpenIdToken in L<Paws::CognitoIdentity>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

