
package Paws::EC2::CancelBundleTaskResult {
  use Moose;
  has BundleTask => (is => 'ro', isa => 'Paws::EC2::BundleTask', xmlname => 'bundleInstanceTask', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::CancelBundleTaskResult

=head1 ATTRIBUTES

=head2 BundleTask => Paws::EC2::BundleTask

  

Information about the bundle task.











=cut

