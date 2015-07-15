
package Paws::EC2::ModifyVolumeAttribute {
  use Moose;
  has AutoEnableIO => (is => 'ro', isa => 'Paws::EC2::AttributeBooleanValue');
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has VolumeId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ModifyVolumeAttribute');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::ModifyVolumeAttribute - Arguments for method ModifyVolumeAttribute on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method ModifyVolumeAttribute on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method ModifyVolumeAttribute.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ModifyVolumeAttribute.

As an example:

  $service_obj->ModifyVolumeAttribute(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AutoEnableIO => Paws::EC2::AttributeBooleanValue

  

Indicates whether the volume should be auto-enabled for I/O operations.










=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 B<REQUIRED> VolumeId => Str

  

The ID of the volume.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ModifyVolumeAttribute in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

