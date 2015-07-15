
package Paws::ElasticBeanstalk::ApplicationDescriptionsMessage {
  use Moose;
  has Applications => (is => 'ro', isa => 'ArrayRef[Paws::ElasticBeanstalk::ApplicationDescription]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticBeanstalk::ApplicationDescriptionsMessage

=head1 ATTRIBUTES

=head2 Applications => ArrayRef[Paws::ElasticBeanstalk::ApplicationDescription]

  

This parameter contains a list of ApplicationDescription.











=cut

