
package Paws::Config::DescribeConfigurationRecorderStatusResponse {
  use Moose;
  has ConfigurationRecordersStatus => (is => 'ro', isa => 'ArrayRef[Paws::Config::ConfigurationRecorderStatus]');

}

### main pod documentation begin ###

=head1 NAME

Paws::Config::DescribeConfigurationRecorderStatusResponse

=head1 ATTRIBUTES

=head2 ConfigurationRecordersStatus => ArrayRef[Paws::Config::ConfigurationRecorderStatus]

  

A list that contains status of the specified recorders.











=cut

1;