
package Paws::KMS::PutKeyPolicy {
  use Moose;
  has KeyId => (is => 'ro', isa => 'Str', required => 1);
  has Policy => (is => 'ro', isa => 'Str', required => 1);
  has PolicyName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'PutKeyPolicy');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::KMS::PutKeyPolicy - Arguments for method PutKeyPolicy on Paws::KMS

=head1 DESCRIPTION

This class represents the parameters used for calling the method PutKeyPolicy on the 
AWS Key Management Service service. Use the attributes of this class
as arguments to method PutKeyPolicy.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to PutKeyPolicy.

As an example:

  $service_obj->PutKeyPolicy(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> KeyId => Str

  

A unique identifier for the customer master key. This value can be a
globally unique identifier or the fully specified ARN to a key.

=over

=item * Key ARN Example -
arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012

=item * Globally Unique Key ID Example -
12345678-1234-1234-1234-123456789012

=back










=head2 B<REQUIRED> Policy => Str

  

The policy, in JSON format, to be attached to the key.










=head2 B<REQUIRED> PolicyName => Str

  

Name of the policy to be attached. Currently, the only supported name
is "default".












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method PutKeyPolicy in L<Paws::KMS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

