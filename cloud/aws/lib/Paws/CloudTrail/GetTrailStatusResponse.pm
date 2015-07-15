
package Paws::CloudTrail::GetTrailStatusResponse {
  use Moose;
  has IsLogging => (is => 'ro', isa => 'Bool');
  has LatestCloudWatchLogsDeliveryError => (is => 'ro', isa => 'Str');
  has LatestCloudWatchLogsDeliveryTime => (is => 'ro', isa => 'Str');
  has LatestDeliveryError => (is => 'ro', isa => 'Str');
  has LatestDeliveryTime => (is => 'ro', isa => 'Str');
  has LatestNotificationError => (is => 'ro', isa => 'Str');
  has LatestNotificationTime => (is => 'ro', isa => 'Str');
  has StartLoggingTime => (is => 'ro', isa => 'Str');
  has StopLoggingTime => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::CloudTrail::GetTrailStatusResponse

=head1 ATTRIBUTES

=head2 IsLogging => Bool

  

Whether the CloudTrail is currently logging AWS API calls.









=head2 LatestCloudWatchLogsDeliveryError => Str

  

Displays any CloudWatch Logs error that CloudTrail encountered when
attempting to deliver logs to CloudWatch Logs.









=head2 LatestCloudWatchLogsDeliveryTime => Str

  

Displays the most recent date and time when CloudTrail delivered logs
to CloudWatch Logs.









=head2 LatestDeliveryError => Str

  

Displays any Amazon S3 error that CloudTrail encountered when
attempting to deliver log files to the designated bucket. For more
information see the topic Error Responses in the Amazon S3 API
Reference.









=head2 LatestDeliveryTime => Str

  

Specifies the date and time that CloudTrail last delivered log files to
an account's Amazon S3 bucket.









=head2 LatestNotificationError => Str

  

Displays any Amazon SNS error that CloudTrail encountered when
attempting to send a notification. For more information about Amazon
SNS errors, see the Amazon SNS Developer Guide.









=head2 LatestNotificationTime => Str

  

Specifies the date and time of the most recent Amazon SNS notification
that CloudTrail has written a new log file to an account's Amazon S3
bucket.









=head2 StartLoggingTime => Str

  

Specifies the most recent date and time when CloudTrail started
recording API calls for an AWS account.









=head2 StopLoggingTime => Str

  

Specifies the most recent date and time when CloudTrail stopped
recording API calls for an AWS account.











=cut

1;