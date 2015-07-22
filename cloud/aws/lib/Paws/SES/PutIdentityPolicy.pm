
package Paws::SES::PutIdentityPolicy {
  use Moose;
  has Identity => (is => 'ro', isa => 'Str', required => 1);
  has Policy => (is => 'ro', isa => 'Str', required => 1);
  has PolicyName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'PutIdentityPolicy');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::SES::PutIdentityPolicyResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'PutIdentityPolicyResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SES::PutIdentityPolicy - Arguments for method PutIdentityPolicy on Paws::SES

=head1 DESCRIPTION

This class represents the parameters used for calling the method PutIdentityPolicy on the 
Amazon Simple Email Service service. Use the attributes of this class
as arguments to method PutIdentityPolicy.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to PutIdentityPolicy.

As an example:

  $service_obj->PutIdentityPolicy(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> Identity => Str

  

The identity to which the policy will apply. You can specify an
identity by using its name or by using its Amazon Resource Name (ARN).
Examples: C<user@example.com>, C<example.com>,
C<arn:aws:ses:us-east-1:123456789012:identity/example.com>.

To successfully call this API, you must own the identity.










=head2 B<REQUIRED> Policy => Str

  

The text of the policy in JSON format. The policy cannot exceed 4 KB.

For information about the syntax of sending authorization policies, see
the Amazon SES Developer Guide.










=head2 B<REQUIRED> PolicyName => Str

  

The name of the policy.

The policy name cannot exceed 64 characters and can only include
alphanumeric characters, dashes, and underscores.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method PutIdentityPolicy in L<Paws::SES>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

