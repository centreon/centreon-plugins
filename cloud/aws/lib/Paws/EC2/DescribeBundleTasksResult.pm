
package Paws::EC2::DescribeBundleTasksResult {
  use Moose;
  has BundleTasks => (is => 'ro', isa => 'ArrayRef[Paws::EC2::BundleTask]', xmlname => 'bundleInstanceTasksSet', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeBundleTasksResult

=head1 ATTRIBUTES

=head2 BundleTasks => ArrayRef[Paws::EC2::BundleTask]

  

Information about one or more bundle tasks.











=cut

