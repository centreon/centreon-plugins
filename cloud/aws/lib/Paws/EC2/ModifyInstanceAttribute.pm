
package Paws::EC2::ModifyInstanceAttribute {
  use Moose;
  has Attribute => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'attribute' );
  has BlockDeviceMappings => (is => 'ro', isa => 'ArrayRef[Paws::EC2::InstanceBlockDeviceMappingSpecification]', traits => ['NameInRequest'], request_name => 'blockDeviceMapping' );
  has DisableApiTermination => (is => 'ro', isa => 'Paws::EC2::AttributeBooleanValue', traits => ['NameInRequest'], request_name => 'disableApiTermination' );
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has EbsOptimized => (is => 'ro', isa => 'Paws::EC2::AttributeBooleanValue', traits => ['NameInRequest'], request_name => 'ebsOptimized' );
  has Groups => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'GroupId' );
  has InstanceId => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'instanceId' , required => 1);
  has InstanceInitiatedShutdownBehavior => (is => 'ro', isa => 'Paws::EC2::AttributeValue', traits => ['NameInRequest'], request_name => 'instanceInitiatedShutdownBehavior' );
  has InstanceType => (is => 'ro', isa => 'Paws::EC2::AttributeValue', traits => ['NameInRequest'], request_name => 'instanceType' );
  has Kernel => (is => 'ro', isa => 'Paws::EC2::AttributeValue', traits => ['NameInRequest'], request_name => 'kernel' );
  has Ramdisk => (is => 'ro', isa => 'Paws::EC2::AttributeValue', traits => ['NameInRequest'], request_name => 'ramdisk' );
  has SourceDestCheck => (is => 'ro', isa => 'Paws::EC2::AttributeBooleanValue');
  has SriovNetSupport => (is => 'ro', isa => 'Paws::EC2::AttributeValue', traits => ['NameInRequest'], request_name => 'sriovNetSupport' );
  has UserData => (is => 'ro', isa => 'Paws::EC2::BlobAttributeValue', traits => ['NameInRequest'], request_name => 'userData' );
  has Value => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'value' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ModifyInstanceAttribute');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::ModifyInstanceAttribute - Arguments for method ModifyInstanceAttribute on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method ModifyInstanceAttribute on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method ModifyInstanceAttribute.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ModifyInstanceAttribute.

As an example:

  $service_obj->ModifyInstanceAttribute(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Attribute => Str

  

The name of the attribute.










=head2 BlockDeviceMappings => ArrayRef[Paws::EC2::InstanceBlockDeviceMappingSpecification]

  

Modifies the C<DeleteOnTermination> attribute for volumes that are
currently attached. The volume must be owned by the caller. If no value
is specified for C<DeleteOnTermination>, the default is C<true> and the
volume is deleted when the instance is terminated.

To add instance store volumes to an Amazon EBS-backed instance, you
must add them when you launch the instance. For more information, see
Updating the Block Device Mapping when Launching an Instance in the
I<Amazon Elastic Compute Cloud User Guide>.










=head2 DisableApiTermination => Paws::EC2::AttributeBooleanValue

  

If the value is C<true>, you can't terminate the instance using the
Amazon EC2 console, CLI, or API; otherwise, you can.










=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 EbsOptimized => Paws::EC2::AttributeBooleanValue

  

Specifies whether the instance is optimized for EBS I/O. This
optimization provides dedicated throughput to Amazon EBS and an
optimized configuration stack to provide optimal EBS I/O performance.
This optimization isn't available with all instance types. Additional
usage charges apply when using an EBS Optimized instance.










=head2 Groups => ArrayRef[Str]

  

[EC2-VPC] Changes the security groups of the instance. You must specify
at least one security group, even if it's just the default security
group for the VPC. You must specify the security group ID, not the
security group name.










=head2 B<REQUIRED> InstanceId => Str

  

The ID of the instance.










=head2 InstanceInitiatedShutdownBehavior => Paws::EC2::AttributeValue

  

Specifies whether an instance stops or terminates when you initiate
shutdown from the instance (using the operating system command for
system shutdown).










=head2 InstanceType => Paws::EC2::AttributeValue

  

Changes the instance type to the specified value. For more information,
see Instance Types. If the instance type is not valid, the error
returned is C<InvalidInstanceAttributeValue>.










=head2 Kernel => Paws::EC2::AttributeValue

  

Changes the instance's kernel to the specified value. We recommend that
you use PV-GRUB instead of kernels and RAM disks. For more information,
see PV-GRUB.










=head2 Ramdisk => Paws::EC2::AttributeValue

  

Changes the instance's RAM disk to the specified value. We recommend
that you use PV-GRUB instead of kernels and RAM disks. For more
information, see PV-GRUB.










=head2 SourceDestCheck => Paws::EC2::AttributeBooleanValue

  

Specifies whether source/destination checking is enabled. A value of
C<true> means that checking is enabled, and C<false> means checking is
disabled. This value must be C<false> for a NAT instance to perform
NAT.










=head2 SriovNetSupport => Paws::EC2::AttributeValue

  

Set to C<simple> to enable enhanced networking for the instance.

There is no way to disable enhanced networking at this time.

This option is supported only for HVM instances. Specifying this option
with a PV instance can make it unreachable.










=head2 UserData => Paws::EC2::BlobAttributeValue

  

Changes the instance's user data to the specified value.










=head2 Value => Str

  

A new value for the attribute. Use only with the C<kernel>, C<ramdisk>,
C<userData>, C<disableApiTermination>, or
C<intanceInitiateShutdownBehavior> attribute.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ModifyInstanceAttribute in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

