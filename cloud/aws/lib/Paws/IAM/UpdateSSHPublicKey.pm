
package Paws::IAM::UpdateSSHPublicKey {
  use Moose;
  has SSHPublicKeyId => (is => 'ro', isa => 'Str', required => 1);
  has Status => (is => 'ro', isa => 'Str', required => 1);
  has UserName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UpdateSSHPublicKey');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::UpdateSSHPublicKey - Arguments for method UpdateSSHPublicKey on Paws::IAM

=head1 DESCRIPTION

This class represents the parameters used for calling the method UpdateSSHPublicKey on the 
AWS Identity and Access Management service. Use the attributes of this class
as arguments to method UpdateSSHPublicKey.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UpdateSSHPublicKey.

As an example:

  $service_obj->UpdateSSHPublicKey(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> SSHPublicKeyId => Str

  

The unique identifier for the SSH public key.










=head2 B<REQUIRED> Status => Str

  

The status to assign to the SSH public key. C<Active> means the key can
be used for authentication with an AWS CodeCommit repository.
C<Inactive> means the key cannot be used.










=head2 B<REQUIRED> UserName => Str

  

The name of the IAM user associated with the SSH public key.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UpdateSSHPublicKey in L<Paws::IAM>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

