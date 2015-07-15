
package Paws::OpsWorks::DescribeDeploymentsResult {
  use Moose;
  has Deployments => (is => 'ro', isa => 'ArrayRef[Paws::OpsWorks::Deployment]');

}

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::DescribeDeploymentsResult

=head1 ATTRIBUTES

=head2 Deployments => ArrayRef[Paws::OpsWorks::Deployment]

  

An array of C<Deployment> objects that describe the deployments.











=cut

1;