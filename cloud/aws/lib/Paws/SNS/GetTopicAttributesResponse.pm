
package Paws::SNS::GetTopicAttributesResponse {
  use Moose;
  has Attributes => (is => 'ro', isa => 'Paws::SNS::TopicAttributesMap');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SNS::GetTopicAttributesResponse

=head1 ATTRIBUTES

=head2 Attributes => Paws::SNS::TopicAttributesMap

  

A map of the topic's attributes. Attributes in this map include the
following:

=over

=item * C<TopicArn> -- the topic's ARN

=item * C<Owner> -- the AWS account ID of the topic's owner

=item * C<Policy> -- the JSON serialization of the topic's access
control policy

=item * C<DisplayName> -- the human-readable name used in the "From"
field for notifications to email and email-json endpoints

=item * C<SubscriptionsPending> -- the number of subscriptions pending
confirmation on this topic

=item * C<SubscriptionsConfirmed> -- the number of confirmed
subscriptions on this topic

=item * C<SubscriptionsDeleted> -- the number of deleted subscriptions
on this topic

=item * C<DeliveryPolicy> -- the JSON serialization of the topic's
delivery policy

=item * C<EffectiveDeliveryPolicy> -- the JSON serialization of the
effective delivery policy that takes into account system defaults

=back











=cut

