
package Paws::CognitoIdentity::GetId {
  use Moose;
  has AccountId => (is => 'ro', isa => 'Str');
  has IdentityPoolId => (is => 'ro', isa => 'Str', required => 1);
  has Logins => (is => 'ro', isa => 'Paws::CognitoIdentity::LoginsMap');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'GetId');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CognitoIdentity::GetIdResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CognitoIdentity::GetId - Arguments for method GetId on Paws::CognitoIdentity

=head1 DESCRIPTION

This class represents the parameters used for calling the method GetId on the 
Amazon Cognito Identity service. Use the attributes of this class
as arguments to method GetId.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to GetId.

As an example:

  $service_obj->GetId(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AccountId => Str

  

A standard AWS account ID (9+ digits).










=head2 B<REQUIRED> IdentityPoolId => Str

  

An identity pool ID in the format REGION:GUID.










=head2 Logins => Paws::CognitoIdentity::LoginsMap

  

A set of optional name-value pairs that map provider names to provider
tokens.

The available provider names for C<Logins> are as follows:

=over

=item * Facebook: C<graph.facebook.com>

=item * Google: C<accounts.google.com>

=item * Amazon: C<www.amazon.com>

=item * Twitter: C<www.twitter.com>

=item * Digits: C<www.digits.com>

=back












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method GetId in L<Paws::CognitoIdentity>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

