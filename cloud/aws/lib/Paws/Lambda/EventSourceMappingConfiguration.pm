
package Paws::Lambda::EventSourceMappingConfiguration {
  use Moose;
  has BatchSize => (is => 'ro', isa => 'Int');
  has EventSourceArn => (is => 'ro', isa => 'Str');
  has FunctionArn => (is => 'ro', isa => 'Str');
  has LastModified => (is => 'ro', isa => 'Str');
  has LastProcessingResult => (is => 'ro', isa => 'Str');
  has State => (is => 'ro', isa => 'Str');
  has StateTransitionReason => (is => 'ro', isa => 'Str');
  has UUID => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Lambda::EventSourceMappingConfiguration

=head1 ATTRIBUTES

=head2 BatchSize => Int

  

The largest number of records that AWS Lambda will retrieve from your
event source at the time of invoking your function. Your function
receives an event with all the retrieved records.









=head2 EventSourceArn => Str

  

The Amazon Resource Name (ARN) of the Amazon Kinesis stream that is the
source of events.









=head2 FunctionArn => Str

  

The Lambda function to invoke when AWS Lambda detects an event on the
stream.









=head2 LastModified => Str

  

The UTC time string indicating the last time the event mapping was
updated.









=head2 LastProcessingResult => Str

  

The result of the last AWS Lambda invocation of your Lambda function.









=head2 State => Str

  

The state of the event source mapping. It can be "Creating", "Enabled",
"Disabled", "Enabling", "Disabling", "Updating", or "Deleting".









=head2 StateTransitionReason => Str

  

The reason the event source mapping is in its current state. It is
either user-requested or an AWS Lambda-initiated state transition.









=head2 UUID => Str

  

The AWS Lambda assigned opaque identifier for the mapping.











=cut

