
package Paws::EC2::DescribeConversionTasksResult {
  use Moose;
  has ConversionTasks => (is => 'ro', isa => 'ArrayRef[Paws::EC2::ConversionTask]', xmlname => 'conversionTasks', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeConversionTasksResult

=head1 ATTRIBUTES

=head2 ConversionTasks => ArrayRef[Paws::EC2::ConversionTask]

  

Information about the conversion tasks.











=cut

