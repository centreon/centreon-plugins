
package Paws::ElasticBeanstalk::RetrieveEnvironmentInfoResultMessage {
  use Moose;
  has EnvironmentInfo => (is => 'ro', isa => 'ArrayRef[Paws::ElasticBeanstalk::EnvironmentInfoDescription]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticBeanstalk::RetrieveEnvironmentInfoResultMessage

=head1 ATTRIBUTES

=head2 EnvironmentInfo => ArrayRef[Paws::ElasticBeanstalk::EnvironmentInfoDescription]

  

The EnvironmentInfoDescription of the environment.











=cut

