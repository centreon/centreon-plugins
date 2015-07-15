
package Paws::EC2::DescribeNetworkAcls {
  use Moose;
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has Filters => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Filter]', traits => ['NameInRequest'], request_name => 'Filter' );
  has NetworkAclIds => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'NetworkAclId' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeNetworkAcls');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::DescribeNetworkAclsResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeNetworkAcls - Arguments for method DescribeNetworkAcls on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeNetworkAcls on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method DescribeNetworkAcls.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeNetworkAcls.

As an example:

  $service_obj->DescribeNetworkAcls(Att1 => $value1, Att2 => $value2, ...);

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

C<association.association-id> - The ID of an association ID for the
ACL.

=item *

C<association.network-acl-id> - The ID of the network ACL involved in
the association.

=item *

C<association.subnet-id> - The ID of the subnet involved in the
association.

=item *

C<default> - Indicates whether the ACL is the default network ACL for
the VPC.

=item *

C<entry.cidr> - The CIDR range specified in the entry.

=item *

C<entry.egress> - Indicates whether the entry applies to egress
traffic.

=item *

C<entry.icmp.code> - The ICMP code specified in the entry, if any.

=item *

C<entry.icmp.type> - The ICMP type specified in the entry, if any.

=item *

C<entry.port-range.from> - The start of the port range specified in the
entry.

=item *

C<entry.port-range.to> - The end of the port range specified in the
entry.

=item *

C<entry.protocol> - The protocol specified in the entry (C<tcp> |
C<udp> | C<icmp> or a protocol number).

=item *

C<entry.rule-action> - Allows or denies the matching traffic (C<allow>
| C<deny>).

=item *

C<entry.rule-number> - The number of an entry (in other words, rule) in
the ACL's set of entries.

=item *

C<network-acl-id> - The ID of the network ACL.

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

C<vpc-id> - The ID of the VPC for the network ACL.

=back










=head2 NetworkAclIds => ArrayRef[Str]

  

One or more network ACL IDs.

Default: Describes all your network ACLs.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeNetworkAcls in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

