
package Paws::EC2::DescribeInstances {
  use Moose;
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has Filters => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Filter]', traits => ['NameInRequest'], request_name => 'Filter' );
  has InstanceIds => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'InstanceId' );
  has MaxResults => (is => 'ro', isa => 'Int', traits => ['NameInRequest'], request_name => 'maxResults' );
  has NextToken => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'nextToken' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeInstances');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::DescribeInstancesResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeInstances - Arguments for method DescribeInstances on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeInstances on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method DescribeInstances.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeInstances.

As an example:

  $service_obj->DescribeInstances(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 Filters => ArrayRef[Paws::EC2::Filter]

  

One or more filters.

=over

=item *

C<architecture> - The instance architecture (C<i386> | C<x86_64>).

=item *

C<availability-zone> - The Availability Zone of the instance.

=item *

C<block-device-mapping.attach-time> - The attach time for an EBS volume
mapped to the instance, for example, C<2010-09-15T17:15:20.000Z>.

=item *

C<block-device-mapping.delete-on-termination> - A Boolean that
indicates whether the EBS volume is deleted on instance termination.

=item *

C<block-device-mapping.device-name> - The device name for the EBS
volume (for example, C</dev/sdh> or C<xvdh>).

=item *

C<block-device-mapping.status> - The status for the EBS volume
(C<attaching> | C<attached> | C<detaching> | C<detached>).

=item *

C<block-device-mapping.volume-id> - The volume ID of the EBS volume.

=item *

C<client-token> - The idempotency token you provided when you launched
the instance.

=item *

C<dns-name> - The public DNS name of the instance.

=item *

C<group-id> - The ID of the security group for the instance.
EC2-Classic only.

=item *

C<group-name> - The name of the security group for the instance.
EC2-Classic only.

=item *

C<hypervisor> - The hypervisor type of the instance (C<ovm> | C<xen>).

=item *

C<iam-instance-profile.arn> - The instance profile associated with the
instance. Specified as an ARN.

=item *

C<image-id> - The ID of the image used to launch the instance.

=item *

C<instance-id> - The ID of the instance.

=item *

C<instance-lifecycle> - Indicates whether this is a Spot Instance
(C<spot>).

=item *

C<instance-state-code> - The state of the instance, as a 16-bit
unsigned integer. The high byte is an opaque internal value and should
be ignored. The low byte is set based on the state represented. The
valid values are: 0 (pending), 16 (running), 32 (shutting-down), 48
(terminated), 64 (stopping), and 80 (stopped).

=item *

C<instance-state-name> - The state of the instance (C<pending> |
C<running> | C<shutting-down> | C<terminated> | C<stopping> |
C<stopped>).

=item *

C<instance-type> - The type of instance (for example, C<t2.micro>).

=item *

C<instance.group-id> - The ID of the security group for the instance.

=item *

C<instance.group-name> - The name of the security group for the
instance.

=item *

C<ip-address> - The public IP address of the instance.

=item *

C<kernel-id> - The kernel ID.

=item *

C<key-name> - The name of the key pair used when the instance was
launched.

=item *

C<launch-index> - When launching multiple instances, this is the index
for the instance in the launch group (for example, 0, 1, 2, and so on).

=item *

C<launch-time> - The time when the instance was launched.

=item *

C<monitoring-state> - Indicates whether monitoring is enabled for the
instance (C<disabled> | C<enabled>).

=item *

C<owner-id> - The AWS account ID of the instance owner.

=item *

C<placement-group-name> - The name of the placement group for the
instance.

=item *

C<platform> - The platform. Use C<windows> if you have Windows
instances; otherwise, leave blank.

=item *

C<private-dns-name> - The private DNS name of the instance.

=item *

C<private-ip-address> - The private IP address of the instance.

=item *

C<product-code> - The product code associated with the AMI used to
launch the instance.

=item *

C<product-code.type> - The type of product code (C<devpay> |
C<marketplace>).

=item *

C<ramdisk-id> - The RAM disk ID.

=item *

C<reason> - The reason for the current state of the instance (for
example, shows "User Initiated [date]" when you stop or terminate the
instance). Similar to the state-reason-code filter.

=item *

C<requester-id> - The ID of the entity that launched the instance on
your behalf (for example, AWS Management Console, Auto Scaling, and so
on).

=item *

C<reservation-id> - The ID of the instance's reservation. A reservation
ID is created any time you launch an instance. A reservation ID has a
one-to-one relationship with an instance launch request, but can be
associated with more than one instance if you launch multiple instances
using the same launch request. For example, if you launch one instance,
you'll get one reservation ID. If you launch ten instances using the
same launch request, you'll also get one reservation ID.

=item *

C<root-device-name> - The name of the root device for the instance (for
example, C</dev/sda1> or C</dev/xvda>).

=item *

C<root-device-type> - The type of root device that the instance uses
(C<ebs> | C<instance-store>).

=item *

C<source-dest-check> - Indicates whether the instance performs
source/destination checking. A value of C<true> means that checking is
enabled, and C<false> means checking is disabled. The value must be
C<false> for the instance to perform network address translation (NAT)
in your VPC.

=item *

C<spot-instance-request-id> - The ID of the Spot Instance request.

=item *

C<state-reason-code> - The reason code for the state change.

=item *

C<state-reason-message> - A message that describes the state change.

=item *

C<subnet-id> - The ID of the subnet for the instance.

=item *

C<tag>:I<key>=I<value> - The key/value combination of a tag assigned to
the resource, where C<tag>:I<key> is the tag's key.

=item *

C<tag-key> - The key of a tag assigned to the resource. This filter is
independent of the C<tag-value> filter. For example, if you use both
the filter "tag-key=Purpose" and the filter "tag-value=X", you get any
resources assigned both the tag key Purpose (regardless of what the
tag's value is), and the tag value X (regardless of what the tag's key
is). If you want to list only resources where Purpose is X, see the
C<tag>:I<key>=I<value> filter.

=item *

C<tag-value> - The value of a tag assigned to the resource. This filter
is independent of the C<tag-key> filter.

=item *

C<tenancy> - The tenancy of an instance (C<dedicated> | C<default>).

=item *

C<virtualization-type> - The virtualization type of the instance
(C<paravirtual> | C<hvm>).

=item *

C<vpc-id> - The ID of the VPC that the instance is running in.

=item *

C<network-interface.description> - The description of the network
interface.

=item *

C<network-interface.subnet-id> - The ID of the subnet for the network
interface.

=item *

C<network-interface.vpc-id> - The ID of the VPC for the network
interface.

=item *

C<network-interface.network-interface.id> - The ID of the network
interface.

=item *

C<network-interface.owner-id> - The ID of the owner of the network
interface.

=item *

C<network-interface.availability-zone> - The Availability Zone for the
network interface.

=item *

C<network-interface.requester-id> - The requester ID for the network
interface.

=item *

C<network-interface.requester-managed> - Indicates whether the network
interface is being managed by AWS.

=item *

C<network-interface.status> - The status of the network interface
(C<available>) | C<in-use>).

=item *

C<network-interface.mac-address> - The MAC address of the network
interface.

=item *

C<network-interface-private-dns-name> - The private DNS name of the
network interface.

=item *

C<network-interface.source-dest-check> - Whether the network interface
performs source/destination checking. A value of C<true> means checking
is enabled, and C<false> means checking is disabled. The value must be
C<false> for the network interface to perform network address
translation (NAT) in your VPC.

=item *

C<network-interface.group-id> - The ID of a security group associated
with the network interface.

=item *

C<network-interface.group-name> - The name of a security group
associated with the network interface.

=item *

C<network-interface.attachment.attachment-id> - The ID of the interface
attachment.

=item *

C<network-interface.attachment.instance-id> - The ID of the instance to
which the network interface is attached.

=item *

C<network-interface.attachment.instance-owner-id> - The owner ID of the
instance to which the network interface is attached.

=item *

C<network-interface.addresses.private-ip-address> - The private IP
address associated with the network interface.

=item *

C<network-interface.attachment.device-index> - The device index to
which the network interface is attached.

=item *

C<network-interface.attachment.status> - The status of the attachment
(C<attaching> | C<attached> | C<detaching> | C<detached>).

=item *

C<network-interface.attachment.attach-time> - The time that the network
interface was attached to an instance.

=item *

C<network-interface.attachment.delete-on-termination> - Specifies
whether the attachment is deleted when an instance is terminated.

=item *

C<network-interface.addresses.primary> - Specifies whether the IP
address of the network interface is the primary private IP address.

=item *

C<network-interface.addresses.association.public-ip> - The ID of the
association of an Elastic IP address with a network interface.

=item *

C<network-interface.addresses.association.ip-owner-id> - The owner ID
of the private IP address associated with the network interface.

=item *

C<association.public-ip> - The address of the Elastic IP address bound
to the network interface.

=item *

C<association.ip-owner-id> - The owner of the Elastic IP address
associated with the network interface.

=item *

C<association.allocation-id> - The allocation ID returned when you
allocated the Elastic IP address for your network interface.

=item *

C<association.association-id> - The association ID returned when the
network interface was associated with an IP address.

=back










=head2 InstanceIds => ArrayRef[Str]

  

One or more instance IDs.

Default: Describes all your instances.










=head2 MaxResults => Int

  

The maximum number of results to return for the request in a single
page. The remaining results of the initial request can be seen by
sending another request with the returned C<NextToken> value. This
value can be between 5 and 1000; if C<MaxResults> is given a value
larger than 1000, only 1000 results are returned. You cannot specify
this parameter and the instance IDs parameter in the same request.










=head2 NextToken => Str

  

The token to request the next page of results.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeInstances in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

