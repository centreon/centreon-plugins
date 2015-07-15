
package Paws::StorageGateway::UpdateChapCredentials {
  use Moose;
  has InitiatorName => (is => 'ro', isa => 'Str', required => 1);
  has SecretToAuthenticateInitiator => (is => 'ro', isa => 'Str', required => 1);
  has SecretToAuthenticateTarget => (is => 'ro', isa => 'Str');
  has TargetARN => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UpdateChapCredentials');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::StorageGateway::UpdateChapCredentialsOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::UpdateChapCredentials - Arguments for method UpdateChapCredentials on Paws::StorageGateway

=head1 DESCRIPTION

This class represents the parameters used for calling the method UpdateChapCredentials on the 
AWS Storage Gateway service. Use the attributes of this class
as arguments to method UpdateChapCredentials.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UpdateChapCredentials.

As an example:

  $service_obj->UpdateChapCredentials(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> InitiatorName => Str

  

The iSCSI initiator that connects to the target.










=head2 B<REQUIRED> SecretToAuthenticateInitiator => Str

  

The secret key that the initiator (for example, the Windows client)
must provide to participate in mutual CHAP with the target.

The secret key must be between 12 and 16 bytes when encoded in UTF-8.










=head2 SecretToAuthenticateTarget => Str

  

The secret key that the target must provide to participate in mutual
CHAP with the initiator (e.g. Windows client).

Byte constraints: Minimum bytes of 12. Maximum bytes of 16.

The secret key must be between 12 and 16 bytes when encoded in UTF-8.










=head2 B<REQUIRED> TargetARN => Str

  

The Amazon Resource Name (ARN) of the iSCSI volume target. Use the
DescribeStorediSCSIVolumes operation to return the TargetARN for
specified VolumeARN.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UpdateChapCredentials in L<Paws::StorageGateway>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

