
package Paws::EC2::RunInstances {
  use Moose;
  has AdditionalInfo => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'additionalInfo' );
  has BlockDeviceMappings => (is => 'ro', isa => 'ArrayRef[Paws::EC2::BlockDeviceMapping]', traits => ['NameInRequest'], request_name => 'BlockDeviceMapping' );
  has ClientToken => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'clientToken' );
  has DisableApiTermination => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'disableApiTermination' );
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has EbsOptimized => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'ebsOptimized' );
  has IamInstanceProfile => (is => 'ro', isa => 'Paws::EC2::IamInstanceProfileSpecification', traits => ['NameInRequest'], request_name => 'iamInstanceProfile' );
  has ImageId => (is => 'ro', isa => 'Str', required => 1);
  has InstanceInitiatedShutdownBehavior => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'instanceInitiatedShutdownBehavior' );
  has InstanceType => (is => 'ro', isa => 'Str');
  has KernelId => (is => 'ro', isa => 'Str');
  has KeyName => (is => 'ro', isa => 'Str');
  has MaxCount => (is => 'ro', isa => 'Int', required => 1);
  has MinCount => (is => 'ro', isa => 'Int', required => 1);
  has Monitoring => (is => 'ro', isa => 'Paws::EC2::RunInstancesMonitoringEnabled');
  has NetworkInterfaces => (is => 'ro', isa => 'ArrayRef[Paws::EC2::InstanceNetworkInterfaceSpecification]', traits => ['NameInRequest'], request_name => 'networkInterface' );
  has Placement => (is => 'ro', isa => 'Paws::EC2::Placement');
  has PrivateIpAddress => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'privateIpAddress' );
  has RamdiskId => (is => 'ro', isa => 'Str');
  has SecurityGroupIds => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'SecurityGroupId' );
  has SecurityGroups => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'SecurityGroup' );
  has SubnetId => (is => 'ro', isa => 'Str');
  has UserData => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'RunInstances');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::Reservation');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::RunInstances - Arguments for method RunInstances on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method RunInstances on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method RunInstances.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to RunInstances.

As an example:

  $service_obj->RunInstances(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AdditionalInfo => Str

  

Reserved.










=head2 BlockDeviceMappings => ArrayRef[Paws::EC2::BlockDeviceMapping]

  

The block device mapping.










=head2 ClientToken => Str

  

Unique, case-sensitive identifier you provide to ensure the idempotency
of the request. For more information, see Ensuring Idempotency.

Constraints: Maximum 64 ASCII characters










=head2 DisableApiTermination => Bool

  

If you set this parameter to C<true>, you can't terminate the instance
using the Amazon EC2 console, CLI, or API; otherwise, you can. If you
set this parameter to C<true> and then later want to be able to
terminate the instance, you must first change the value of the
C<disableApiTermination> attribute to C<false> using
ModifyInstanceAttribute. Alternatively, if you set
C<InstanceInitiatedShutdownBehavior> to C<terminate>, you can terminate
the instance by running the shutdown command from the instance.

Default: C<false>










=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 EbsOptimized => Bool

  

Indicates whether the instance is optimized for EBS I/O. This
optimization provides dedicated throughput to Amazon EBS and an
optimized configuration stack to provide optimal EBS I/O performance.
This optimization isn't available with all instance types. Additional
usage charges apply when using an EBS-optimized instance.

Default: C<false>










=head2 IamInstanceProfile => Paws::EC2::IamInstanceProfileSpecification

  

The IAM instance profile.










=head2 B<REQUIRED> ImageId => Str

  

The ID of the AMI, which you can get by calling DescribeImages.










=head2 InstanceInitiatedShutdownBehavior => Str

  

Indicates whether an instance stops or terminates when you initiate
shutdown from the instance (using the operating system command for
system shutdown).

Default: C<stop>










=head2 InstanceType => Str

  

The instance type. For more information, see Instance Types in the
I<Amazon Elastic Compute Cloud User Guide>.

Default: C<m1.small>










=head2 KernelId => Str

  

The ID of the kernel.

We recommend that you use PV-GRUB instead of kernels and RAM disks. For
more information, see PV-GRUB in the I<Amazon Elastic Compute Cloud
User Guide>.










=head2 KeyName => Str

  

The name of the key pair. You can create a key pair using CreateKeyPair
or ImportKeyPair.

If you do not specify a key pair, you can't connect to the instance
unless you choose an AMI that is configured to allow users another way
to log in.










=head2 B<REQUIRED> MaxCount => Int

  

The maximum number of instances to launch. If you specify more
instances than Amazon EC2 can launch in the target Availability Zone,
Amazon EC2 launches the largest possible number of instances above
C<MinCount>.

Constraints: Between 1 and the maximum number you're allowed for the
specified instance type. For more information about the default limits,
and how to request an increase, see How many instances can I run in
Amazon EC2 in the Amazon EC2 General FAQ.










=head2 B<REQUIRED> MinCount => Int

  

The minimum number of instances to launch. If you specify a minimum
that is more instances than Amazon EC2 can launch in the target
Availability Zone, Amazon EC2 launches no instances.

Constraints: Between 1 and the maximum number you're allowed for the
specified instance type. For more information about the default limits,
and how to request an increase, see How many instances can I run in
Amazon EC2 in the Amazon EC2 General FAQ.










=head2 Monitoring => Paws::EC2::RunInstancesMonitoringEnabled

  

The monitoring for the instance.










=head2 NetworkInterfaces => ArrayRef[Paws::EC2::InstanceNetworkInterfaceSpecification]

  

One or more network interfaces.










=head2 Placement => Paws::EC2::Placement

  

The placement for the instance.










=head2 PrivateIpAddress => Str

  

[EC2-VPC] The primary IP address. You must specify a value from the IP
address range of the subnet.

Only one private IP address can be designated as primary. Therefore,
you can't specify this parameter if C<PrivateIpAddresses.n.Primary> is
set to C<true> and C<PrivateIpAddresses.n.PrivateIpAddress> is set to
an IP address.

Default: We select an IP address from the IP address range of the
subnet.










=head2 RamdiskId => Str

  

The ID of the RAM disk.

We recommend that you use PV-GRUB instead of kernels and RAM disks. For
more information, see PV-GRUB in the I<Amazon Elastic Compute Cloud
User Guide>.










=head2 SecurityGroupIds => ArrayRef[Str]

  

One or more security group IDs. You can create a security group using
CreateSecurityGroup.

Default: Amazon EC2 uses the default security group.










=head2 SecurityGroups => ArrayRef[Str]

  

[EC2-Classic, default VPC] One or more security group names. For a
nondefault VPC, you must use security group IDs instead.

Default: Amazon EC2 uses the default security group.










=head2 SubnetId => Str

  

[EC2-VPC] The ID of the subnet to launch the instance into.










=head2 UserData => Str

  

The Base64-encoded MIME user data for the instances.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method RunInstances in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

