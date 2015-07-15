
package Paws::SNS::ListSubscriptionsByTopicResponse {
  use Moose;
  has NextToken => (is => 'ro', isa => 'Str');
  has Subscriptions => (is => 'ro', isa => 'ArrayRef[Paws::SNS::Subscription]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SNS::ListSubscriptionsByTopicResponse

=head1 ATTRIBUTES

=head2 NextToken => Str

  

Token to pass along to the next C<ListSubscriptionsByTopic> request.
This element is returned if there are more subscriptions to retrieve.









=head2 Subscriptions => ArrayRef[Paws::SNS::Subscription]

  

A list of subscriptions.











=cut

