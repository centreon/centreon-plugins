
package Paws::SES::ListIdentityPolicies {
  use Moose;
  has Identity => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListIdentityPolicies');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::SES::ListIdentityPoliciesResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ListIdentityPoliciesResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SES::ListIdentityPolicies - Arguments for method ListIdentityPolicies on Paws::SES

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListIdentityPolicies on the 
Amazon Simple Email Service service. Use the attributes of this class
as arguments to method ListIdentityPolicies.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListIdentityPolicies.

As an example:

  $service_obj->ListIdentityPolicies(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> Identity => Str

  

The identity that is associated with the policy for which the policies
will be listed. You can specify an identity by using its name or by
using its Amazon Resource Name (ARN). Examples: C<user@example.com>,
C<example.com>,
C<arn:aws:ses:us-east-1:123456789012:identity/example.com>.

To successfully call this API, you must own the identity.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListIdentityPolicies in L<Paws::SES>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

