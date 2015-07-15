
package Paws::CognitoIdentity::SetIdentityPoolRoles {
  use Moose;
  has IdentityPoolId => (is => 'ro', isa => 'Str', required => 1);
  has Roles => (is => 'ro', isa => 'Paws::CognitoIdentity::RolesMap', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'SetIdentityPoolRoles');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CognitoIdentity::SetIdentityPoolRoles - Arguments for method SetIdentityPoolRoles on Paws::CognitoIdentity

=head1 DESCRIPTION

This class represents the parameters used for calling the method SetIdentityPoolRoles on the 
Amazon Cognito Identity service. Use the attributes of this class
as arguments to method SetIdentityPoolRoles.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to SetIdentityPoolRoles.

As an example:

  $service_obj->SetIdentityPoolRoles(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> IdentityPoolId => Str

  

An identity pool ID in the format REGION:GUID.










=head2 B<REQUIRED> Roles => Paws::CognitoIdentity::RolesMap

  

The map of roles associated with this pool. For a given role, the key
will be either "authenticated" or "unauthenticated" and the value will
be the Role ARN.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method SetIdentityPoolRoles in L<Paws::CognitoIdentity>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

