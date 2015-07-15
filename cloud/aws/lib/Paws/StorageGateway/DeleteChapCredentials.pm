
package Paws::StorageGateway::DeleteChapCredentials {
  use Moose;
  has InitiatorName => (is => 'ro', isa => 'Str', required => 1);
  has TargetARN => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DeleteChapCredentials');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::StorageGateway::DeleteChapCredentialsOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::DeleteChapCredentials - Arguments for method DeleteChapCredentials on Paws::StorageGateway

=head1 DESCRIPTION

This class represents the parameters used for calling the method DeleteChapCredentials on the 
AWS Storage Gateway service. Use the attributes of this class
as arguments to method DeleteChapCredentials.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DeleteChapCredentials.

As an example:

  $service_obj->DeleteChapCredentials(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> InitiatorName => Str

  

The iSCSI initiator that connects to the target.










=head2 B<REQUIRED> TargetARN => Str

  

The Amazon Resource Name (ARN) of the iSCSI volume target. Use the
DescribeStorediSCSIVolumes operation to return to retrieve the
TargetARN for specified VolumeARN.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DeleteChapCredentials in L<Paws::StorageGateway>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

