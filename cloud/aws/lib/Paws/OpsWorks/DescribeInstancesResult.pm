
package Paws::OpsWorks::DescribeInstancesResult {
  use Moose;
  has Instances => (is => 'ro', isa => 'ArrayRef[Paws::OpsWorks::Instance]');

}

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::DescribeInstancesResult

=head1 ATTRIBUTES

=head2 Instances => ArrayRef[Paws::OpsWorks::Instance]

  

An array of C<Instance> objects that describe the instances.











=cut

1;