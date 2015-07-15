
package Paws::EC2::DescribeClassicLinkInstancesResult {
  use Moose;
  has Instances => (is => 'ro', isa => 'ArrayRef[Paws::EC2::ClassicLinkInstance]', xmlname => 'instancesSet', traits => ['Unwrapped',]);
  has NextToken => (is => 'ro', isa => 'Str', xmlname => 'nextToken', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeClassicLinkInstancesResult

=head1 ATTRIBUTES

=head2 Instances => ArrayRef[Paws::EC2::ClassicLinkInstance]

  

Information about one or more linked EC2-Classic instances.









=head2 NextToken => Str

  

The token to use to retrieve the next page of results. This value is
C<null> when there are no more results to return.











=cut

