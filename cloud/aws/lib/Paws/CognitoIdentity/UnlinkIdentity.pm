
package Paws::CognitoIdentity::UnlinkIdentity {
  use Moose;
  has IdentityId => (is => 'ro', isa => 'Str', required => 1);
  has Logins => (is => 'ro', isa => 'Paws::CognitoIdentity::LoginsMap', required => 1);
  has LoginsToRemove => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UnlinkIdentity');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CognitoIdentity::UnlinkIdentity - Arguments for method UnlinkIdentity on Paws::CognitoIdentity

=head1 DESCRIPTION

This class represents the parameters used for calling the method UnlinkIdentity on the 
Amazon Cognito Identity service. Use the attributes of this class
as arguments to method UnlinkIdentity.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UnlinkIdentity.

As an example:

  $service_obj->UnlinkIdentity(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> IdentityId => Str

  

A unique identifier in the format REGION:GUID.










=head2 B<REQUIRED> Logins => Paws::CognitoIdentity::LoginsMap

  

A set of optional name-value pairs that map provider names to provider
tokens.










=head2 B<REQUIRED> LoginsToRemove => ArrayRef[Str]

  

Provider names to unlink from this identity.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UnlinkIdentity in L<Paws::CognitoIdentity>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

