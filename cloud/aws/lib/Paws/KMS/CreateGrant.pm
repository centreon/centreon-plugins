
package Paws::KMS::CreateGrant {
  use Moose;
  has Constraints => (is => 'ro', isa => 'Paws::KMS::GrantConstraints');
  has GranteePrincipal => (is => 'ro', isa => 'Str', required => 1);
  has GrantTokens => (is => 'ro', isa => 'ArrayRef[Str]');
  has KeyId => (is => 'ro', isa => 'Str', required => 1);
  has Operations => (is => 'ro', isa => 'ArrayRef[Str]');
  has RetiringPrincipal => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateGrant');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::KMS::CreateGrantResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::KMS::CreateGrant - Arguments for method CreateGrant on Paws::KMS

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateGrant on the 
AWS Key Management Service service. Use the attributes of this class
as arguments to method CreateGrant.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateGrant.

As an example:

  $service_obj->CreateGrant(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Constraints => Paws::KMS::GrantConstraints

  

Specifies the conditions under which the actions specified by the
C<Operations> parameter are allowed.










=head2 B<REQUIRED> GranteePrincipal => Str

  

Principal given permission by the grant to use the key identified by
the C<keyId> parameter.










=head2 GrantTokens => ArrayRef[Str]

  

For more information, see Grant Tokens.










=head2 B<REQUIRED> KeyId => Str

  

A unique identifier for the customer master key. This value can be a
globally unique identifier or the fully specified ARN to a key.

=over

=item * Key ARN Example -
arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012

=item * Globally Unique Key ID Example -
12345678-1234-1234-1234-123456789012

=back










=head2 Operations => ArrayRef[Str]

  

List of operations permitted by the grant. This can be any combination
of one or more of the following values:

=over

=item 1. Decrypt

=item 2. Encrypt

=item 3. GenerateDataKey

=item 4. GenerateDataKeyWithoutPlaintext

=item 5. ReEncryptFrom

=item 6. ReEncryptTo

=item 7. CreateGrant

=item 8. RetireGrant

=back










=head2 RetiringPrincipal => Str

  

Principal given permission to retire the grant. For more information,
see RetireGrant.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateGrant in L<Paws::KMS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

