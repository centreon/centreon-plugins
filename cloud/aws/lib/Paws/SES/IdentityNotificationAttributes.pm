package Paws::SES::IdentityNotificationAttributes {
  use Moose;
  has BounceTopic => (is => 'ro', isa => 'Str');
  has ComplaintTopic => (is => 'ro', isa => 'Str');
  has DeliveryTopic => (is => 'ro', isa => 'Str');
  has ForwardingEnabled => (is => 'ro', isa => 'Bool', required => 1);
}
1;
