
package Paws::KMS::ReEncrypt {
  use Moose;
  has CiphertextBlob => (is => 'ro', isa => 'Str', required => 1);
  has DestinationEncryptionContext => (is => 'ro', isa => 'Paws::KMS::EncryptionContextType');
  has DestinationKeyId => (is => 'ro', isa => 'Str', required => 1);
  has GrantTokens => (is => 'ro', isa => 'ArrayRef[Str]');
  has SourceEncryptionContext => (is => 'ro', isa => 'Paws::KMS::EncryptionContextType');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ReEncrypt');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::KMS::ReEncryptResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::KMS::ReEncrypt - Arguments for method ReEncrypt on Paws::KMS

=head1 DESCRIPTION

This class represents the parameters used for calling the method ReEncrypt on the 
AWS Key Management Service service. Use the attributes of this class
as arguments to method ReEncrypt.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ReEncrypt.

As an example:

  $service_obj->ReEncrypt(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> CiphertextBlob => Str

  

Ciphertext of the data to re-encrypt.










=head2 DestinationEncryptionContext => Paws::KMS::EncryptionContextType

  

Encryption context to be used when the data is re-encrypted.










=head2 B<REQUIRED> DestinationKeyId => Str

  

A unique identifier for the customer master key used to re-encrypt the
data. This value can be a globally unique identifier, a fully specified
ARN to either an alias or a key, or an alias name prefixed by "alias/".

=over

=item * Key ARN Example -
arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012

=item * Alias ARN Example -
arn:aws:kms:us-east-1:123456789012:alias/MyAliasName

=item * Globally Unique Key ID Example -
12345678-1234-1234-1234-123456789012

=item * Alias Name Example - alias/MyAliasName

=back










=head2 GrantTokens => ArrayRef[Str]

  

For more information, see Grant Tokens.










=head2 SourceEncryptionContext => Paws::KMS::EncryptionContextType

  

Encryption context used to encrypt and decrypt the data specified in
the C<CiphertextBlob> parameter.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ReEncrypt in L<Paws::KMS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

