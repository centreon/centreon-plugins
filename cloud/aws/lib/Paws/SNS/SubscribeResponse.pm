
package Paws::SNS::SubscribeResponse {
  use Moose;
  has SubscriptionArn => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SNS::SubscribeResponse

=head1 ATTRIBUTES

=head2 SubscriptionArn => Str

  

The ARN of the subscription, if the service was able to create a
subscription immediately (without requiring endpoint owner
confirmation).











=cut

