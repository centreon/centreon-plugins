
package Paws::Config::DescribeConfigurationRecordersResponse {
  use Moose;
  has ConfigurationRecorders => (is => 'ro', isa => 'ArrayRef[Paws::Config::ConfigurationRecorder]');

}

### main pod documentation begin ###

=head1 NAME

Paws::Config::DescribeConfigurationRecordersResponse

=head1 ATTRIBUTES

=head2 ConfigurationRecorders => ArrayRef[Paws::Config::ConfigurationRecorder]

  

A list that contains the descriptions of the specified configuration
recorders.











=cut

1;