
package Paws::EC2::DescribeTags {
  use Moose;
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has Filters => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Filter]', traits => ['NameInRequest'], request_name => 'Filter' );
  has MaxResults => (is => 'ro', isa => 'Int', traits => ['NameInRequest'], request_name => 'maxResults' );
  has NextToken => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'nextToken' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeTags');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::DescribeTagsResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeTags - Arguments for method DescribeTags on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeTags on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method DescribeTags.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeTags.

As an example:

  $service_obj->DescribeTags(Att1 => $value1, Att2 => $value2, ...);

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

C<key> - The tag key.

=item *

C<resource-id> - The resource ID.

=item *

C<resource-type> - The resource type (C<customer-gateway> |
C<dhcp-options> | C<image> | C<instance> | C<internet-gateway> |
C<network-acl> | C<network-interface> | C<reserved-instances> |
C<route-table> | C<security-group> | C<snapshot> |
C<spot-instances-request> | C<subnet> | C<volume> | C<vpc> |
C<vpn-connection> | C<vpn-gateway>).

=item *

C<value> - The tag value.

=back










=head2 MaxResults => Int

  

The maximum number of results to return for the request in a single
page. The remaining results of the initial request can be seen by
sending another request with the returned C<NextToken> value. This
value can be between 5 and 1000; if C<MaxResults> is given a value
larger than 1000, only 1000 results are returned.










=head2 NextToken => Str

  

The token to retrieve the next page of results.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeTags in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

