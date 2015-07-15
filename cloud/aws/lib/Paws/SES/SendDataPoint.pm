package Paws::SES::SendDataPoint {
  use Moose;
  has Bounces => (is => 'ro', isa => 'Int');
  has Complaints => (is => 'ro', isa => 'Int');
  has DeliveryAttempts => (is => 'ro', isa => 'Int');
  has Rejects => (is => 'ro', isa => 'Int');
  has Timestamp => (is => 'ro', isa => 'Str');
}
1;
