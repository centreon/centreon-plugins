
package Paws::EC2::DescribeVpcEndpointServicesResult {
  use Moose;
  has NextToken => (is => 'ro', isa => 'Str', xmlname => 'nextToken', traits => ['Unwrapped',]);
  has ServiceNames => (is => 'ro', isa => 'ArrayRef[Str]', xmlname => 'serviceNameSet', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeVpcEndpointServicesResult

=head1 ATTRIBUTES

=head2 NextToken => Str

  

The token to use when requesting the next set of items. If there are no
additional items to return, the string is empty.









=head2 ServiceNames => ArrayRef[Str]

  

A list of supported AWS services.











=cut

