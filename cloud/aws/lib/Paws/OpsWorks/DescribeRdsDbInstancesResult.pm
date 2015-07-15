
package Paws::OpsWorks::DescribeRdsDbInstancesResult {
  use Moose;
  has RdsDbInstances => (is => 'ro', isa => 'ArrayRef[Paws::OpsWorks::RdsDbInstance]');

}

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::DescribeRdsDbInstancesResult

=head1 ATTRIBUTES

=head2 RdsDbInstances => ArrayRef[Paws::OpsWorks::RdsDbInstance]

  

An a array of C<RdsDbInstance> objects that describe the instances.











=cut

1;