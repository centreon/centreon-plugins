
package Paws::SES::GetSendQuotaResponse {
  use Moose;
  has Max24HourSend => (is => 'ro', isa => 'Num');
  has MaxSendRate => (is => 'ro', isa => 'Num');
  has SentLast24Hours => (is => 'ro', isa => 'Num');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SES::GetSendQuotaResponse

=head1 ATTRIBUTES

=head2 Max24HourSend => Num

  

The maximum number of emails the user is allowed to send in a 24-hour
interval. A value of -1 signifies an unlimited quota.









=head2 MaxSendRate => Num

  

The maximum number of emails that Amazon SES can accept from the user's
account per second.

The rate at which Amazon SES accepts the user's messages might be less
than the maximum send rate.









=head2 SentLast24Hours => Num

  

The number of emails sent during the previous 24 hours.











=cut

