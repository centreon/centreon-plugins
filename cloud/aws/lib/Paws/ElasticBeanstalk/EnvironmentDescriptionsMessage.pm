
package Paws::ElasticBeanstalk::EnvironmentDescriptionsMessage {
  use Moose;
  has Environments => (is => 'ro', isa => 'ArrayRef[Paws::ElasticBeanstalk::EnvironmentDescription]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticBeanstalk::EnvironmentDescriptionsMessage

=head1 ATTRIBUTES

=head2 Environments => ArrayRef[Paws::ElasticBeanstalk::EnvironmentDescription]

  

Returns an EnvironmentDescription list.











=cut

