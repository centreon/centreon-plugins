
package Paws::CognitoIdentity::LookupDeveloperIdentity {
  use Moose;
  has DeveloperUserIdentifier => (is => 'ro', isa => 'Str');
  has IdentityId => (is => 'ro', isa => 'Str');
  has IdentityPoolId => (is => 'ro', isa => 'Str', required => 1);
  has MaxResults => (is => 'ro', isa => 'Int');
  has NextToken => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'LookupDeveloperIdentity');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CognitoIdentity::LookupDeveloperIdentityResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CognitoIdentity::LookupDeveloperIdentity - Arguments for method LookupDeveloperIdentity on Paws::CognitoIdentity

=head1 DESCRIPTION

This class represents the parameters used for calling the method LookupDeveloperIdentity on the 
Amazon Cognito Identity service. Use the attributes of this class
as arguments to method LookupDeveloperIdentity.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to LookupDeveloperIdentity.

As an example:

  $service_obj->LookupDeveloperIdentity(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 DeveloperUserIdentifier => Str

  

A unique ID used by your backend authentication process to identify a
user. Typically, a developer identity provider would issue many
developer user identifiers, in keeping with the number of users.










=head2 IdentityId => Str

  

A unique identifier in the format REGION:GUID.










=head2 B<REQUIRED> IdentityPoolId => Str

  

An identity pool ID in the format REGION:GUID.










=head2 MaxResults => Int

  

The maximum number of identities to return.










=head2 NextToken => Str

  

A pagination token. The first call you make will have C<NextToken> set
to null. After that the service will return C<NextToken> values as
needed. For example, let's say you make a request with C<MaxResults>
set to 10, and there are 20 matches in the database. The service will
return a pagination token as a part of the response. This token can be
used to call the API again and get results starting from the 11th
match.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method LookupDeveloperIdentity in L<Paws::CognitoIdentity>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

