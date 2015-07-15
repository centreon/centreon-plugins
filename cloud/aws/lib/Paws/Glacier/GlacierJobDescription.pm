
package Paws::Glacier::GlacierJobDescription {
  use Moose;
  has Action => (is => 'ro', isa => 'Str');
  has ArchiveId => (is => 'ro', isa => 'Str');
  has ArchiveSHA256TreeHash => (is => 'ro', isa => 'Str');
  has ArchiveSizeInBytes => (is => 'ro', isa => 'Int');
  has Completed => (is => 'ro', isa => 'Bool');
  has CompletionDate => (is => 'ro', isa => 'Str');
  has CreationDate => (is => 'ro', isa => 'Str');
  has InventoryRetrievalParameters => (is => 'ro', isa => 'Paws::Glacier::InventoryRetrievalJobDescription');
  has InventorySizeInBytes => (is => 'ro', isa => 'Int');
  has JobDescription => (is => 'ro', isa => 'Str');
  has JobId => (is => 'ro', isa => 'Str');
  has RetrievalByteRange => (is => 'ro', isa => 'Str');
  has SHA256TreeHash => (is => 'ro', isa => 'Str');
  has SNSTopic => (is => 'ro', isa => 'Str');
  has StatusCode => (is => 'ro', isa => 'Str');
  has StatusMessage => (is => 'ro', isa => 'Str');
  has VaultARN => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Glacier::GlacierJobDescription

=head1 ATTRIBUTES

=head2 Action => Str

  

The job type. It is either ArchiveRetrieval or InventoryRetrieval.









=head2 ArchiveId => Str

  

For an ArchiveRetrieval job, this is the archive ID requested for
download. Otherwise, this field is null.









=head2 ArchiveSHA256TreeHash => Str

  

The SHA256 tree hash of the entire archive for an archive retrieval.
For inventory retrieval jobs, this field is null.









=head2 ArchiveSizeInBytes => Int

  

For an ArchiveRetrieval job, this is the size in bytes of the archive
being requested for download. For the InventoryRetrieval job, the value
is null.









=head2 Completed => Bool

  

The job status. When a job is completed, you get the job's output.









=head2 CompletionDate => Str

  

The UTC time that the archive retrieval request completed. While the
job is in progress, the value will be null.









=head2 CreationDate => Str

  

The UTC date when the job was created. A string representation of ISO
8601 date format, for example, "2012-03-20T17:03:43.221Z".









=head2 InventoryRetrievalParameters => Paws::Glacier::InventoryRetrievalJobDescription

  

Parameters used for range inventory retrieval.









=head2 InventorySizeInBytes => Int

  

For an InventoryRetrieval job, this is the size in bytes of the
inventory requested for download. For the ArchiveRetrieval job, the
value is null.









=head2 JobDescription => Str

  

The job description you provided when you initiated the job.









=head2 JobId => Str

  

An opaque string that identifies an Amazon Glacier job.









=head2 RetrievalByteRange => Str

  

The retrieved byte range for archive retrieval jobs in the form
"I<StartByteValue>-I<EndByteValue>" If no range was specified in the
archive retrieval, then the whole archive is retrieved and
I<StartByteValue> equals 0 and I<EndByteValue> equals the size of the
archive minus 1. For inventory retrieval jobs this field is null.









=head2 SHA256TreeHash => Str

  

For an ArchiveRetrieval job, it is the checksum of the archive.
Otherwise, the value is null.

The SHA256 tree hash value for the requested range of an archive. If
the Initiate a Job request for an archive specified a tree-hash aligned
range, then this field returns a value.

For the specific case when the whole archive is retrieved, this value
is the same as the ArchiveSHA256TreeHash value.

This field is null in the following situations:

=over

=item *

Archive retrieval jobs that specify a range that is not tree-hash
aligned.

=back

=over

=item *

Archival jobs that specify a range that is equal to the whole archive
and the job status is InProgress.

=back

=over

=item *

Inventory jobs.

=back









=head2 SNSTopic => Str

  

An Amazon Simple Notification Service (Amazon SNS) topic that receives
notification.









=head2 StatusCode => Str

  

The status code can be InProgress, Succeeded, or Failed, and indicates
the status of the job.









=head2 StatusMessage => Str

  

A friendly message that describes the job status.









=head2 VaultARN => Str

  

The Amazon Resource Name (ARN) of the vault from which the archive
retrieval was requested.











=cut

