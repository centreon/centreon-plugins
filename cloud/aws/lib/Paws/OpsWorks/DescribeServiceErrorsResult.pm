
package Paws::OpsWorks::DescribeServiceErrorsResult {
  use Moose;
  has ServiceErrors => (is => 'ro', isa => 'ArrayRef[Paws::OpsWorks::ServiceError]');

}

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::DescribeServiceErrorsResult

=head1 ATTRIBUTES

=head2 ServiceErrors => ArrayRef[Paws::OpsWorks::ServiceError]

  

An array of C<ServiceError> objects that describe the specified service
errors.











=cut

1;