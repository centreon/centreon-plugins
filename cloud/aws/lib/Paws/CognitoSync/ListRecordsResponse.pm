
package Paws::CognitoSync::ListRecordsResponse {
  use Moose;
  has Count => (is => 'ro', isa => 'Int');
  has DatasetDeletedAfterRequestedSyncCount => (is => 'ro', isa => 'Bool');
  has DatasetExists => (is => 'ro', isa => 'Bool');
  has DatasetSyncCount => (is => 'ro', isa => 'Int');
  has LastModifiedBy => (is => 'ro', isa => 'Str');
  has MergedDatasetNames => (is => 'ro', isa => 'ArrayRef[Str]');
  has NextToken => (is => 'ro', isa => 'Str');
  has Records => (is => 'ro', isa => 'ArrayRef[Paws::CognitoSync::Record]');
  has SyncSessionToken => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CognitoSync::ListRecordsResponse

=head1 ATTRIBUTES

=head2 Count => Int

  

Total number of records.









=head2 DatasetDeletedAfterRequestedSyncCount => Bool

  

A boolean value specifying whether to delete the dataset locally.









=head2 DatasetExists => Bool

  

Indicates whether the dataset exists.









=head2 DatasetSyncCount => Int

  

Server sync count for this dataset.









=head2 LastModifiedBy => Str

  

The user/device that made the last change to this record.









=head2 MergedDatasetNames => ArrayRef[Str]

  

Names of merged datasets.









=head2 NextToken => Str

  

A pagination token for obtaining the next page of results.









=head2 Records => ArrayRef[Paws::CognitoSync::Record]

  

A list of all records.









=head2 SyncSessionToken => Str

  

A token containing a session ID, identity ID, and expiration.











=cut

