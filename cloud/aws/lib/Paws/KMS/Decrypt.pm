
package Paws::KMS::Decrypt {
  use Moose;
  has CiphertextBlob => (is => 'ro', isa => 'Str', required => 1);
  has EncryptionContext => (is => 'ro', isa => 'Paws::KMS::EncryptionContextType');
  has GrantTokens => (is => 'ro', isa => 'ArrayRef[Str]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'Decrypt');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::KMS::DecryptResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::KMS::Decrypt - Arguments for method Decrypt on Paws::KMS

=head1 DESCRIPTION

This class represents the parameters used for calling the method Decrypt on the 
AWS Key Management Service service. Use the attributes of this class
as arguments to method Decrypt.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to Decrypt.

As an example:

  $service_obj->Decrypt(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> CiphertextBlob => Str

  

Ciphertext to be decrypted. The blob includes metadata.










=head2 EncryptionContext => Paws::KMS::EncryptionContextType

  

The encryption context. If this was specified in the Encrypt function,
it must be specified here or the decryption operation will fail. For
more information, see Encryption Context.










=head2 GrantTokens => ArrayRef[Str]

  

For more information, see Grant Tokens.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method Decrypt in L<Paws::KMS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

