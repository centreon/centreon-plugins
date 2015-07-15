
package Paws::RedShift::LoggingStatus {
  use Moose;
  has BucketName => (is => 'ro', isa => 'Str');
  has LastFailureMessage => (is => 'ro', isa => 'Str');
  has LastFailureTime => (is => 'ro', isa => 'Str');
  has LastSuccessfulDeliveryTime => (is => 'ro', isa => 'Str');
  has LoggingEnabled => (is => 'ro', isa => 'Bool');
  has S3KeyPrefix => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RedShift::LoggingStatus

=head1 ATTRIBUTES

=head2 BucketName => Str

  

The name of the S3 bucket where the log files are stored.









=head2 LastFailureMessage => Str

  

The message indicating that logs failed to be delivered.









=head2 LastFailureTime => Str

  

The last time when logs failed to be delivered.









=head2 LastSuccessfulDeliveryTime => Str

  

The last time when logs were delivered.









=head2 LoggingEnabled => Bool

  

C<true> if logging is on, C<false> if logging is off.









=head2 S3KeyPrefix => Str

  

The prefix applied to the log file names.











=cut

