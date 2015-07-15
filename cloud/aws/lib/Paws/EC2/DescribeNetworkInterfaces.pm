
package Paws::EC2::DescribeNetworkInterfaces {
  use Moose;
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has Filters => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Filter]', traits => ['NameInRequest'], request_name => 'filter' );
  has NetworkInterfaceIds => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'NetworkInterfaceId' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeNetworkInterfaces');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::DescribeNetworkInterfacesResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeNetworkInterfaces - Arguments for method DescribeNetworkInterfaces on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeNetworkInterfaces on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method DescribeNetworkInterfaces.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeNetworkInterfaces.

As an example:

  $service_obj->DescribeNetworkInterfaces(Att1 => $value1, Att2 => $value2, ...);

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

C<addresses.private-ip-address> - The private IP addresses associated
with the network interface.

=item *

C<addresses.primary> - Whether the private IP address is the primary IP
address associated with the network interface.

=item *

C<addresses.association.public-ip> - The association ID returned when
the network interface was associated with the Elastic IP address.

=item *

C<addresses.association.owner-id> - The owner ID of the addresses
associated with the network interface.

=item *

C<association.association-id> - The association ID returned when the
network interface was associated with an IP address.

=item *

C<association.allocation-id> - The allocation ID returned when you
allocated the Elastic IP address for your network interface.

=item *

C<association.ip-owner-id> - The owner of the Elastic IP address
associated with the network interface.

=item *

C<association.public-ip> - The address of the Elastic IP address bound
to the network interface.

=item *

C<association.public-dns-name> - The public DNS name for the network
interface.

=item *

C<attachment.attachment-id> - The ID of the interface attachment.

=item *

C<attachment.instance-id> - The ID of the instance to which the network
interface is attached.

=item *

C<attachment.instance-owner-id> - The owner ID of the instance to which
the network interface is attached.

=item *

C<attachment.device-index> - The device index to which the network
interface is attached.

=item *

C<attachment.status> - The status of the attachment (C<attaching> |
C<attached> | C<detaching> | C<detached>).

=item *

C<attachment.attach.time> - The time that the network interface was
attached to an instance.

=item *

C<attachment.delete-on-termination> - Indicates whether the attachment
is deleted when an instance is terminated.

=item *

C<availability-zone> - The Availability Zone of the network interface.

=item *

C<description> - The description of the network interface.

=item *

C<group-id> - The ID of a security group associated with the network
interface.

=item *

C<group-name> - The name of a security group associated with the
network interface.

=item *

C<mac-address> - The MAC address of the network interface.

=item *

C<network-interface-id> - The ID of the network interface.

=item *

C<owner-id> - The AWS account ID of the network interface owner.

=item *

C<private-ip-address> - The private IP address or addresses of the
network interface.

=item *

C<private-dns-name> - The private DNS name of the network interface.

=item *

C<requester-id> - The ID of the entity that launched the instance on
your behalf (for example, AWS Management Console, Auto Scaling, and so
on).

=item *

C<requester-managed> - Indicates whether the network interface is being
managed by an AWS service (for example, AWS Management Console, Auto
Scaling, and so on).

=item *

C<source-desk-check> - Indicates whether the network interface performs
source/destination checking. A value of C<true> means checking is
enabled, and C<false> means checking is disabled. The value must be
C<false> for the network interface to perform Network Address
Translation (NAT) in your VPC.

=item *

C<status> - The status of the network interface. If the network
interface is not attached to an instance, the status is C<available>;
if a network interface is attached to an instance the status is
C<in-use>.

=item *

C<subnet-id> - The ID of the subnet for the network interface.

=item *

C<tag>:I<key>=I<value> - The key/value combination of a tag assigned to
the resource.

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

C<vpc-id> - The ID of the VPC for the network interface.

=back










=head2 NetworkInterfaceIds => ArrayRef[Str]

  

One or more network interface IDs.

Default: Describes all your network interfaces.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeNetworkInterfaces in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

