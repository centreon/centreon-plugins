
package Paws::SES::GetIdentityPolicies {
  use Moose;
  has Identity => (is => 'ro', isa => 'Str', required => 1);
  has PolicyNames => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'GetIdentityPolicies');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::SES::GetIdentityPoliciesResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'GetIdentityPoliciesResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SES::GetIdentityPolicies - Arguments for method GetIdentityPolicies on Paws::SES

=head1 DESCRIPTION

This class represents the parameters used for calling the method GetIdentityPolicies on the 
Amazon Simple Email Service service. Use the attributes of this class
as arguments to method GetIdentityPolicies.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to GetIdentityPolicies.

As an example:

  $service_obj->GetIdentityPolicies(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> Identity => Str

  

The identity for which the policies will be retrieved. You can specify
an identity by using its name or by using its Amazon Resource Name
(ARN). Examples: C<user@example.com>, C<example.com>,
C<arn:aws:ses:us-east-1:123456789012:identity/example.com>.

To successfully call this API, you must own the identity.










=head2 B<REQUIRED> PolicyNames => ArrayRef[Str]

  

A list of the names of policies to be retrieved. You can retrieve a
maximum of 20 policies at a time. If you do not know the names of the
policies that are attached to the identity, you can use
C<ListIdentityPolicies>.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method GetIdentityPolicies in L<Paws::SES>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

