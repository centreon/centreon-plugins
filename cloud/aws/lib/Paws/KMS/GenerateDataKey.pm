
package Paws::KMS::GenerateDataKey {
  use Moose;
  has EncryptionContext => (is => 'ro', isa => 'Paws::KMS::EncryptionContextType');
  has GrantTokens => (is => 'ro', isa => 'ArrayRef[Str]');
  has KeyId => (is => 'ro', isa => 'Str', required => 1);
  has KeySpec => (is => 'ro', isa => 'Str');
  has NumberOfBytes => (is => 'ro', isa => 'Int');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'GenerateDataKey');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::KMS::GenerateDataKeyResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::KMS::GenerateDataKey - Arguments for method GenerateDataKey on Paws::KMS

=head1 DESCRIPTION

This class represents the parameters used for calling the method GenerateDataKey on the 
AWS Key Management Service service. Use the attributes of this class
as arguments to method GenerateDataKey.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to GenerateDataKey.

As an example:

  $service_obj->GenerateDataKey(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 EncryptionContext => Paws::KMS::EncryptionContextType

  

Name/value pair that contains additional data to be authenticated
during the encryption and decryption processes that use the key. This
value is logged by AWS CloudTrail to provide context around the data
encrypted by the key.










=head2 GrantTokens => ArrayRef[Str]

  

For more information, see Grant Tokens.










=head2 B<REQUIRED> KeyId => Str

  

A unique identifier for the customer master key. This value can be a
globally unique identifier, a fully specified ARN to either an alias or
a key, or an alias name prefixed by "alias/".

=over

=item * Key ARN Example -
arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012

=item * Alias ARN Example -
arn:aws:kms:us-east-1:123456789012:alias/MyAliasName

=item * Globally Unique Key ID Example -
12345678-1234-1234-1234-123456789012

=item * Alias Name Example - alias/MyAliasName

=back










=head2 KeySpec => Str

  

Value that identifies the encryption algorithm and key size to generate
a data key for. Currently this can be AES_128 or AES_256.










=head2 NumberOfBytes => Int

  

Integer that contains the number of bytes to generate. Common values
are 128, 256, 512, and 1024. 1024 is the current limit. We recommend
that you use the C<KeySpec> parameter instead.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method GenerateDataKey in L<Paws::KMS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

