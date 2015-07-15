
package Paws::EC2::DescribeSecurityGroups {
  use Moose;
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has Filters => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Filter]', traits => ['NameInRequest'], request_name => 'Filter' );
  has GroupIds => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'GroupId' );
  has GroupNames => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'GroupName' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeSecurityGroups');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::DescribeSecurityGroupsResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeSecurityGroups - Arguments for method DescribeSecurityGroups on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeSecurityGroups on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method DescribeSecurityGroups.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeSecurityGroups.

As an example:

  $service_obj->DescribeSecurityGroups(Att1 => $value1, Att2 => $value2, ...);

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

C<description> - The description of the security group.

=item *

C<egress.ip-permission.prefix-list-id> - The ID (prefix) of the AWS
service to which the security group allows access.

=item *

C<group-id> - The ID of the security group.

=item *

C<group-name> - The name of the security group.

=item *

C<ip-permission.cidr> - A CIDR range that has been granted permission.

=item *

C<ip-permission.from-port> - The start of port range for the TCP and
UDP protocols, or an ICMP type number.

=item *

C<ip-permission.group-id> - The ID of a security group that has been
granted permission.

=item *

C<ip-permission.group-name> - The name of a security group that has
been granted permission.

=item *

C<ip-permission.protocol> - The IP protocol for the permission (C<tcp>
| C<udp> | C<icmp> or a protocol number).

=item *

C<ip-permission.to-port> - The end of port range for the TCP and UDP
protocols, or an ICMP code.

=item *

C<ip-permission.user-id> - The ID of an AWS account that has been
granted permission.

=item *

C<owner-id> - The AWS account ID of the owner of the security group.

=item *

C<tag-key> - The key of a tag assigned to the security group.

=item *

C<tag-value> - The value of a tag assigned to the security group.

=item *

C<vpc-id> - The ID of the VPC specified when the security group was
created.

=back










=head2 GroupIds => ArrayRef[Str]

  

One or more security group IDs. Required for security groups in a
nondefault VPC.

Default: Describes all your security groups.










=head2 GroupNames => ArrayRef[Str]

  

[EC2-Classic and default VPC only] One or more security group names.
You can specify either the security group name or the security group
ID. For security groups in a nondefault VPC, use the C<group-name>
filter to describe security groups by name.

Default: Describes all your security groups.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeSecurityGroups in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

