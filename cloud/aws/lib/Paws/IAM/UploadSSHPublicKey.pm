
package Paws::IAM::UploadSSHPublicKey {
  use Moose;
  has SSHPublicKeyBody => (is => 'ro', isa => 'Str', required => 1);
  has UserName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UploadSSHPublicKey');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::IAM::UploadSSHPublicKeyResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'UploadSSHPublicKeyResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::UploadSSHPublicKey - Arguments for method UploadSSHPublicKey on Paws::IAM

=head1 DESCRIPTION

This class represents the parameters used for calling the method UploadSSHPublicKey on the 
AWS Identity and Access Management service. Use the attributes of this class
as arguments to method UploadSSHPublicKey.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UploadSSHPublicKey.

As an example:

  $service_obj->UploadSSHPublicKey(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> SSHPublicKeyBody => Str

  

The SSH public key. The public key must be encoded in ssh-rsa format or
PEM format.










=head2 B<REQUIRED> UserName => Str

  

The name of the IAM user to associate the SSH public key with.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UploadSSHPublicKey in L<Paws::IAM>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

