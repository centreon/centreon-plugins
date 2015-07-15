
package Paws::EC2::DescribeVpcEndpointsResult {
  use Moose;
  has NextToken => (is => 'ro', isa => 'Str', xmlname => 'nextToken', traits => ['Unwrapped',]);
  has VpcEndpoints => (is => 'ro', isa => 'ArrayRef[Paws::EC2::VpcEndpoint]', xmlname => 'vpcEndpointSet', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeVpcEndpointsResult

=head1 ATTRIBUTES

=head2 NextToken => Str

  

The token to use when requesting the next set of items. If there are no
additional items to return, the string is empty.









=head2 VpcEndpoints => ArrayRef[Paws::EC2::VpcEndpoint]

  

Information about the endpoints.











=cut

