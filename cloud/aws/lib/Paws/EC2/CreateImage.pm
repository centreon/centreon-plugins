
package Paws::EC2::CreateImage {
  use Moose;
  has BlockDeviceMappings => (is => 'ro', isa => 'ArrayRef[Paws::EC2::BlockDeviceMapping]', traits => ['NameInRequest'], request_name => 'blockDeviceMapping' );
  has Description => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'description' );
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has InstanceId => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'instanceId' , required => 1);
  has Name => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'name' , required => 1);
  has NoReboot => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'noReboot' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateImage');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::CreateImageResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::CreateImage - Arguments for method CreateImage on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateImage on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method CreateImage.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateImage.

As an example:

  $service_obj->CreateImage(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 BlockDeviceMappings => ArrayRef[Paws::EC2::BlockDeviceMapping]

  

Information about one or more block device mappings.










=head2 Description => Str

  

A description for the new image.










=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 B<REQUIRED> InstanceId => Str

  

The ID of the instance.










=head2 B<REQUIRED> Name => Str

  

A name for the new image.

Constraints: 3-128 alphanumeric characters, parentheses (()), square
brackets ([]), spaces ( ), periods (.), slashes (/), dashes (-), single
quotes ('), at-signs (@), or underscores(_)










=head2 NoReboot => Bool

  

By default, this parameter is set to C<false>, which means Amazon EC2
attempts to shut down the instance cleanly before image creation and
then reboots the instance. When the parameter is set to C<true>, Amazon
EC2 doesn't shut down the instance before creating the image. When this
option is used, file system integrity on the created image can't be
guaranteed.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateImage in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

