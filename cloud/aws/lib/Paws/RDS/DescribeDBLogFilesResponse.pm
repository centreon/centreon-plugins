
package Paws::RDS::DescribeDBLogFilesResponse {
  use Moose;
  has DescribeDBLogFiles => (is => 'ro', isa => 'ArrayRef[Paws::RDS::DescribeDBLogFilesDetails]', xmlname => 'DescribeDBLogFilesDetails', traits => ['Unwrapped',]);
  has Marker => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::DescribeDBLogFilesResponse

=head1 ATTRIBUTES

=head2 DescribeDBLogFiles => ArrayRef[Paws::RDS::DescribeDBLogFilesDetails]

  

The DB log files returned.









=head2 Marker => Str

  

A pagination token that can be used in a subsequent DescribeDBLogFiles
request.











=cut

