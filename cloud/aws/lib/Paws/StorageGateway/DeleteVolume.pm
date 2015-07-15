
package Paws::StorageGateway::DeleteVolume {
  use Moose;
  has VolumeARN => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DeleteVolume');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::StorageGateway::DeleteVolumeOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::DeleteVolume - Arguments for method DeleteVolume on Paws::StorageGateway

=head1 DESCRIPTION

This class represents the parameters used for calling the method DeleteVolume on the 
AWS Storage Gateway service. Use the attributes of this class
as arguments to method DeleteVolume.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DeleteVolume.

As an example:

  $service_obj->DeleteVolume(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> VolumeARN => Str

  

The Amazon Resource Name (ARN) of the volume. Use the ListVolumes
operation to return a list of gateway volumes.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DeleteVolume in L<Paws::StorageGateway>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

