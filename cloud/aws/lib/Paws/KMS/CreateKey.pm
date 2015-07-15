
package Paws::KMS::CreateKey {
  use Moose;
  has Description => (is => 'ro', isa => 'Str');
  has KeyUsage => (is => 'ro', isa => 'Str');
  has Policy => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateKey');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::KMS::CreateKeyResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::KMS::CreateKey - Arguments for method CreateKey on Paws::KMS

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateKey on the 
AWS Key Management Service service. Use the attributes of this class
as arguments to method CreateKey.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateKey.

As an example:

  $service_obj->CreateKey(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Description => Str

  

Description of the key. We recommend that you choose a description that
helps your customer decide whether the key is appropriate for a task.










=head2 KeyUsage => Str

  

Specifies the intended use of the key. Currently this defaults to
ENCRYPT/DECRYPT, and only symmetric encryption and decryption are
supported.










=head2 Policy => Str

  

Policy to be attached to the key. This is required and delegates back
to the account. The key is the root of trust.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateKey in L<Paws::KMS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

