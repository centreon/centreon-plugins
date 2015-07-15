
package Paws::CognitoSync::GetBulkPublishDetailsResponse {
  use Moose;
  has BulkPublishCompleteTime => (is => 'ro', isa => 'Str');
  has BulkPublishStartTime => (is => 'ro', isa => 'Str');
  has BulkPublishStatus => (is => 'ro', isa => 'Str');
  has FailureMessage => (is => 'ro', isa => 'Str');
  has IdentityPoolId => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CognitoSync::GetBulkPublishDetailsResponse

=head1 ATTRIBUTES

=head2 BulkPublishCompleteTime => Str

  

If BulkPublishStatus is SUCCEEDED, the time the last bulk publish
operation completed.









=head2 BulkPublishStartTime => Str

  

The date/time at which the last bulk publish was initiated.









=head2 BulkPublishStatus => Str

  

Status of the last bulk publish operation, valid values are:

NOT_STARTED - No bulk publish has been requested for this identity pool

IN_PROGRESS - Data is being published to the configured stream

SUCCEEDED - All data for the identity pool has been published to the
configured stream

FAILED - Some portion of the data has failed to publish, check
FailureMessage for the cause.









=head2 FailureMessage => Str

  

If BulkPublishStatus is FAILED this field will contain the error
message that caused the bulk publish to fail.









=head2 IdentityPoolId => Str

  

A name-spaced GUID (for example,
us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon
Cognito. GUID generation is unique within a region.











=cut

