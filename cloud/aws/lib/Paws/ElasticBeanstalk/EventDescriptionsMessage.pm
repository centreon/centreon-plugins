
package Paws::ElasticBeanstalk::EventDescriptionsMessage {
  use Moose;
  has Events => (is => 'ro', isa => 'ArrayRef[Paws::ElasticBeanstalk::EventDescription]');
  has NextToken => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticBeanstalk::EventDescriptionsMessage

=head1 ATTRIBUTES

=head2 Events => ArrayRef[Paws::ElasticBeanstalk::EventDescription]

  

A list of EventDescription.









=head2 NextToken => Str

  

If returned, this indicates that there are more results to obtain. Use
this token in the next DescribeEvents call to get the next batch of
events.











=cut

