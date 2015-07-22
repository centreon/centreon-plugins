package Paws::Glacier {
  warn "Paws::Glacier is not stable / supported / entirely developed";
  use Moose;
  sub service { 'glacier' }
  sub version { '2012-06-01' }
  sub flattened_arrays { 0 }

  with 'Paws::API::Caller', 'Paws::API::EndpointResolver', 'Paws::Net::V4Signature', 'Paws::Net::RestJsonCaller', 'Paws::Net::RestJsonResponse';

  
  sub AbortMultipartUpload {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Glacier::AbortMultipartUpload', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AddTagsToVault {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Glacier::AddTagsToVault', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CompleteMultipartUpload {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Glacier::CompleteMultipartUpload', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateVault {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Glacier::CreateVault', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteArchive {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Glacier::DeleteArchive', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteVault {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Glacier::DeleteVault', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteVaultAccessPolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Glacier::DeleteVaultAccessPolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteVaultNotifications {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Glacier::DeleteVaultNotifications', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeJob {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Glacier::DescribeJob', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeVault {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Glacier::DescribeVault', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetDataRetrievalPolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Glacier::GetDataRetrievalPolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetJobOutput {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Glacier::GetJobOutput', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetVaultAccessPolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Glacier::GetVaultAccessPolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetVaultNotifications {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Glacier::GetVaultNotifications', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub InitiateJob {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Glacier::InitiateJob', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub InitiateMultipartUpload {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Glacier::InitiateMultipartUpload', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListJobs {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Glacier::ListJobs', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListMultipartUploads {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Glacier::ListMultipartUploads', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListParts {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Glacier::ListParts', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListTagsForVault {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Glacier::ListTagsForVault', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListVaults {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Glacier::ListVaults', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RemoveTagsFromVault {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Glacier::RemoveTagsFromVault', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub SetDataRetrievalPolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Glacier::SetDataRetrievalPolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub SetVaultAccessPolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Glacier::SetVaultAccessPolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub SetVaultNotifications {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Glacier::SetVaultNotifications', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UploadArchive {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Glacier::UploadArchive', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UploadMultipartPart {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Glacier::UploadMultipartPart', @_);
    return $self->caller->do_call($self, $call_object);
  }
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Glacier - Perl Interface to AWS Amazon Glacier

=head1 SYNOPSIS

  use Paws;

  my $obj = Paws->service('Glacier')->new;
  my $res = $obj->Method(
    Arg1 => $val1,
    Arg2 => [ 'V1', 'V2' ],
    # if Arg3 is an object, the HashRef will be used as arguments to the constructor
    # of the arguments type
    Arg3 => { Att1 => 'Val1' },
    # if Arg4 is an array of objects, the HashRefs will be passed as arguments to
    # the constructor of the arguments type
    Arg4 => [ { Att1 => 'Val1'  }, { Att1 => 'Val2' } ],
  );

=head1 DESCRIPTION



Amazon Glacier is a storage solution for "cold data."

Amazon Glacier is an extremely low-cost storage service that provides
secure, durable, and easy-to-use storage for data backup and archival.
With Amazon Glacier, customers can store their data cost effectively
for months, years, or decades. Amazon Glacier also enables customers to
offload the administrative burdens of operating and scaling storage to
AWS, so they don't have to worry about capacity planning, hardware
provisioning, data replication, hardware failure and recovery, or
time-consuming hardware migrations.

Amazon Glacier is a great storage choice when low storage cost is
paramount, your data is rarely retrieved, and retrieval latency of
several hours is acceptable. If your application requires fast or
frequent access to your data, consider using Amazon S3. For more
information, go to Amazon Simple Storage Service (Amazon S3).

You can store any kind of data in any format. There is no maximum limit
on the total amount of data you can store in Amazon Glacier.

If you are a first-time user of Amazon Glacier, we recommend that you
begin by reading the following sections in the I<Amazon Glacier
Developer Guide>:

=over

=item *

What is Amazon Glacier - This section of the Developer Guide describes
the underlying data model, the operations it supports, and the AWS SDKs
that you can use to interact with the service.

=item *

Getting Started with Amazon Glacier - The Getting Started section walks
you through the process of creating a vault, uploading archives,
creating jobs to download archives, retrieving the job output, and
deleting archives.

=back










=head1 METHODS

=head2 AbortMultipartUpload(accountId => Str, uploadId => Str, vaultName => Str)

Each argument is described in detail in: L<Paws::Glacier::AbortMultipartUpload>

Returns: nothing

  

This operation aborts a multipart upload identified by the upload ID.

After the Abort Multipart Upload request succeeds, you cannot upload
any more parts to the multipart upload or complete the multipart
upload. Aborting a completed upload fails. However, aborting an
already-aborted upload will succeed, for a short time. For more
information about uploading a part and completing a multipart upload,
see UploadMultipartPart and CompleteMultipartUpload.

This operation is idempotent.

An AWS account has full permission to perform all operations (actions).
However, AWS Identity and Access Management (IAM) users don't have any
permissions by default. You must grant them explicit permission to
perform specific actions. For more information, see Access Control
Using AWS Identity and Access Management (IAM).

For conceptual information and underlying REST API, go to Working with
Archives in Amazon Glacier and Abort Multipart Upload in the I<Amazon
Glacier Developer Guide>.











=head2 AddTagsToVault(accountId => Str, vaultName => Str, [Tags => Paws::Glacier::TagMap])

Each argument is described in detail in: L<Paws::Glacier::AddTagsToVault>

Returns: nothing

  

This operation adds the specified tags to a vault. Each tag is composed
of a key and a value. Each vault can have up to 10 tags. If your
request would cause the tag limit for the vault to be exceeded, the
operation throws the C<LimitExceededException> error. If a tag already
exists on the vault under a specified key, the existing key value will
be overwritten. For more information about tags, see Tagging Amazon
Glacier Resources.











=head2 CompleteMultipartUpload(accountId => Str, uploadId => Str, vaultName => Str, [archiveSize => Str, checksum => Str])

Each argument is described in detail in: L<Paws::Glacier::CompleteMultipartUpload>

Returns: a L<Paws::Glacier::ArchiveCreationOutput> instance

  

You call this operation to inform Amazon Glacier that all the archive
parts have been uploaded and that Amazon Glacier can now assemble the
archive from the uploaded parts. After assembling and saving the
archive to the vault, Amazon Glacier returns the URI path of the newly
created archive resource. Using the URI path, you can then access the
archive. After you upload an archive, you should save the archive ID
returned to retrieve the archive at a later point. You can also get the
vault inventory to obtain a list of archive IDs in a vault. For more
information, see InitiateJob.

In the request, you must include the computed SHA256 tree hash of the
entire archive you have uploaded. For information about computing a
SHA256 tree hash, see Computing Checksums. On the server side, Amazon
Glacier also constructs the SHA256 tree hash of the assembled archive.
If the values match, Amazon Glacier saves the archive to the vault;
otherwise, it returns an error, and the operation fails. The ListParts
operation returns a list of parts uploaded for a specific multipart
upload. It includes checksum information for each uploaded part that
can be used to debug a bad checksum issue.

Additionally, Amazon Glacier also checks for any missing content ranges
when assembling the archive, if missing content ranges are found,
Amazon Glacier returns an error and the operation fails.

Complete Multipart Upload is an idempotent operation. After your first
successful complete multipart upload, if you call the operation again
within a short period, the operation will succeed and return the same
archive ID. This is useful in the event you experience a network issue
that causes an aborted connection or receive a 500 server error, in
which case you can repeat your Complete Multipart Upload request and
get the same archive ID without creating duplicate archives. Note,
however, that after the multipart upload completes, you cannot call the
List Parts operation and the multipart upload will not appear in List
Multipart Uploads response, even if idempotent complete is possible.

An AWS account has full permission to perform all operations (actions).
However, AWS Identity and Access Management (IAM) users don't have any
permissions by default. You must grant them explicit permission to
perform specific actions. For more information, see Access Control
Using AWS Identity and Access Management (IAM).

For conceptual information and underlying REST API, go to Uploading
Large Archives in Parts (Multipart Upload) and Complete Multipart
Upload in the I<Amazon Glacier Developer Guide>.











=head2 CreateVault(accountId => Str, vaultName => Str)

Each argument is described in detail in: L<Paws::Glacier::CreateVault>

Returns: a L<Paws::Glacier::CreateVaultOutput> instance

  

This operation creates a new vault with the specified name. The name of
the vault must be unique within a region for an AWS account. You can
create up to 1,000 vaults per account. If you need to create more
vaults, contact Amazon Glacier.

You must use the following guidelines when naming a vault.

=over

=item *

Names can be between 1 and 255 characters long.

=item *

Allowed characters are a-z, A-Z, 0-9, '_' (underscore), '-' (hyphen),
and '.' (period).

=back

This operation is idempotent.

An AWS account has full permission to perform all operations (actions).
However, AWS Identity and Access Management (IAM) users don't have any
permissions by default. You must grant them explicit permission to
perform specific actions. For more information, see Access Control
Using AWS Identity and Access Management (IAM).

For conceptual information and underlying REST API, go to Creating a
Vault in Amazon Glacier and Create Vault in the I<Amazon Glacier
Developer Guide>.











=head2 DeleteArchive(accountId => Str, archiveId => Str, vaultName => Str)

Each argument is described in detail in: L<Paws::Glacier::DeleteArchive>

Returns: nothing

  

This operation deletes an archive from a vault. Subsequent requests to
initiate a retrieval of this archive will fail. Archive retrievals that
are in progress for this archive ID may or may not succeed according to
the following scenarios:

=over

=item * If the archive retrieval job is actively preparing the data for
download when Amazon Glacier receives the delete archive request, the
archival retrieval operation might fail.

=item * If the archive retrieval job has successfully prepared the
archive for download when Amazon Glacier receives the delete archive
request, you will be able to download the output.

=back

This operation is idempotent. Attempting to delete an already-deleted
archive does not result in an error.

An AWS account has full permission to perform all operations (actions).
However, AWS Identity and Access Management (IAM) users don't have any
permissions by default. You must grant them explicit permission to
perform specific actions. For more information, see Access Control
Using AWS Identity and Access Management (IAM).

For conceptual information and underlying REST API, go to Deleting an
Archive in Amazon Glacier and Delete Archive in the I<Amazon Glacier
Developer Guide>.











=head2 DeleteVault(accountId => Str, vaultName => Str)

Each argument is described in detail in: L<Paws::Glacier::DeleteVault>

Returns: nothing

  

This operation deletes a vault. Amazon Glacier will delete a vault only
if there are no archives in the vault as of the last inventory and
there have been no writes to the vault since the last inventory. If
either of these conditions is not satisfied, the vault deletion fails
(that is, the vault is not removed) and Amazon Glacier returns an
error. You can use DescribeVault to return the number of archives in a
vault, and you can use Initiate a Job (POST jobs) to initiate a new
inventory retrieval for a vault. The inventory contains the archive IDs
you use to delete archives using Delete Archive (DELETE archive).

This operation is idempotent.

An AWS account has full permission to perform all operations (actions).
However, AWS Identity and Access Management (IAM) users don't have any
permissions by default. You must grant them explicit permission to
perform specific actions. For more information, see Access Control
Using AWS Identity and Access Management (IAM).

For conceptual information and underlying REST API, go to Deleting a
Vault in Amazon Glacier and Delete Vault in the I<Amazon Glacier
Developer Guide>.











=head2 DeleteVaultAccessPolicy(accountId => Str, vaultName => Str)

Each argument is described in detail in: L<Paws::Glacier::DeleteVaultAccessPolicy>

Returns: nothing

  

This operation deletes the access policy associated with the specified
vault. The operation is eventually consistent; that is, it might take
some time for Amazon Glacier to completely remove the access policy,
and you might still see the effect of the policy for a short time after
you send the delete request.

This operation is idempotent. You can invoke delete multiple times,
even if there is no policy associated with the vault. For more
information about vault access policies, see Amazon Glacier Access
Control with Vault Access Policies.











=head2 DeleteVaultNotifications(accountId => Str, vaultName => Str)

Each argument is described in detail in: L<Paws::Glacier::DeleteVaultNotifications>

Returns: nothing

  

This operation deletes the notification configuration set for a vault.
The operation is eventually consistent; that is, it might take some
time for Amazon Glacier to completely disable the notifications and you
might still receive some notifications for a short time after you send
the delete request.

An AWS account has full permission to perform all operations (actions).
However, AWS Identity and Access Management (IAM) users don't have any
permissions by default. You must grant them explicit permission to
perform specific actions. For more information, see Access Control
Using AWS Identity and Access Management (IAM).

For conceptual information and underlying REST API, go to Configuring
Vault Notifications in Amazon Glacier and Delete Vault Notification
Configuration in the Amazon Glacier Developer Guide.











=head2 DescribeJob(accountId => Str, jobId => Str, vaultName => Str)

Each argument is described in detail in: L<Paws::Glacier::DescribeJob>

Returns: a L<Paws::Glacier::GlacierJobDescription> instance

  

This operation returns information about a job you previously
initiated, including the job initiation date, the user who initiated
the job, the job status code/message and the Amazon SNS topic to notify
after Amazon Glacier completes the job. For more information about
initiating a job, see InitiateJob.

This operation enables you to check the status of your job. However, it
is strongly recommended that you set up an Amazon SNS topic and specify
it in your initiate job request so that Amazon Glacier can notify the
topic after it completes the job.

A job ID will not expire for at least 24 hours after Amazon Glacier
completes the job.

An AWS account has full permission to perform all operations (actions).
However, AWS Identity and Access Management (IAM) users don't have any
permissions by default. You must grant them explicit permission to
perform specific actions. For more information, see Access Control
Using AWS Identity and Access Management (IAM).

For information about the underlying REST API, go to Working with
Archives in Amazon Glacier in the I<Amazon Glacier Developer Guide>.











=head2 DescribeVault(accountId => Str, vaultName => Str)

Each argument is described in detail in: L<Paws::Glacier::DescribeVault>

Returns: a L<Paws::Glacier::DescribeVaultOutput> instance

  

This operation returns information about a vault, including the vault's
Amazon Resource Name (ARN), the date the vault was created, the number
of archives it contains, and the total size of all the archives in the
vault. The number of archives and their total size are as of the last
inventory generation. This means that if you add or remove an archive
from a vault, and then immediately use Describe Vault, the change in
contents will not be immediately reflected. If you want to retrieve the
latest inventory of the vault, use InitiateJob. Amazon Glacier
generates vault inventories approximately daily. For more information,
see Downloading a Vault Inventory in Amazon Glacier.

An AWS account has full permission to perform all operations (actions).
However, AWS Identity and Access Management (IAM) users don't have any
permissions by default. You must grant them explicit permission to
perform specific actions. For more information, see Access Control
Using AWS Identity and Access Management (IAM).

For conceptual information and underlying REST API, go to Retrieving
Vault Metadata in Amazon Glacier and Describe Vault in the I<Amazon
Glacier Developer Guide>.











=head2 GetDataRetrievalPolicy(accountId => Str)

Each argument is described in detail in: L<Paws::Glacier::GetDataRetrievalPolicy>

Returns: a L<Paws::Glacier::GetDataRetrievalPolicyOutput> instance

  

This operation returns the current data retrieval policy for the
account and region specified in the GET request. For more information
about data retrieval policies, see Amazon Glacier Data Retrieval
Policies.











=head2 GetJobOutput(accountId => Str, jobId => Str, vaultName => Str, [range => Str])

Each argument is described in detail in: L<Paws::Glacier::GetJobOutput>

Returns: a L<Paws::Glacier::GetJobOutputOutput> instance

  

This operation downloads the output of the job you initiated using
InitiateJob. Depending on the job type you specified when you initiated
the job, the output will be either the content of an archive or a vault
inventory.

A job ID will not expire for at least 24 hours after Amazon Glacier
completes the job. That is, you can download the job output within the
24 hours period after Amazon Glacier completes the job.

If the job output is large, then you can use the C<Range> request
header to retrieve a portion of the output. This allows you to download
the entire output in smaller chunks of bytes. For example, suppose you
have 1 GB of job output you want to download and you decide to download
128 MB chunks of data at a time, which is a total of eight Get Job
Output requests. You use the following process to download the job
output:

=over

=item 1.

Download a 128 MB chunk of output by specifying the appropriate byte
range using the C<Range> header.

=item 2.

Along with the data, the response includes a SHA256 tree hash of the
payload. You compute the checksum of the payload on the client and
compare it with the checksum you received in the response to ensure you
received all the expected data.

=item 3.

Repeat steps 1 and 2 for all the eight 128 MB chunks of output data,
each time specifying the appropriate byte range.

=item 4.

After downloading all the parts of the job output, you have a list of
eight checksum values. Compute the tree hash of these values to find
the checksum of the entire output. Using the DescribeJob API, obtain
job information of the job that provided you the output. The response
includes the checksum of the entire archive stored in Amazon Glacier.
You compare this value with the checksum you computed to ensure you
have downloaded the entire archive content with no errors.

=back

An AWS account has full permission to perform all operations (actions).
However, AWS Identity and Access Management (IAM) users don't have any
permissions by default. You must grant them explicit permission to
perform specific actions. For more information, see Access Control
Using AWS Identity and Access Management (IAM).

For conceptual information and the underlying REST API, go to
Downloading a Vault Inventory, Downloading an Archive, and Get Job
Output











=head2 GetVaultAccessPolicy(accountId => Str, vaultName => Str)

Each argument is described in detail in: L<Paws::Glacier::GetVaultAccessPolicy>

Returns: a L<Paws::Glacier::GetVaultAccessPolicyOutput> instance

  

This operation retrieves the C<access-policy> subresource set on the
vault; for more information on setting this subresource, see Set Vault
Access Policy (PUT access-policy). If there is no access policy set on
the vault, the operation returns a C<404 Not found> error. For more
information about vault access policies, see Amazon Glacier Access
Control with Vault Access Policies.











=head2 GetVaultNotifications(accountId => Str, vaultName => Str)

Each argument is described in detail in: L<Paws::Glacier::GetVaultNotifications>

Returns: a L<Paws::Glacier::GetVaultNotificationsOutput> instance

  

This operation retrieves the C<notification-configuration> subresource
of the specified vault.

For information about setting a notification configuration on a vault,
see SetVaultNotifications. If a notification configuration for a vault
is not set, the operation returns a C<404 Not Found> error. For more
information about vault notifications, see Configuring Vault
Notifications in Amazon Glacier.

An AWS account has full permission to perform all operations (actions).
However, AWS Identity and Access Management (IAM) users don't have any
permissions by default. You must grant them explicit permission to
perform specific actions. For more information, see Access Control
Using AWS Identity and Access Management (IAM).

For conceptual information and underlying REST API, go to Configuring
Vault Notifications in Amazon Glacier and Get Vault Notification
Configuration in the I<Amazon Glacier Developer Guide>.











=head2 InitiateJob(accountId => Str, vaultName => Str, [jobParameters => Paws::Glacier::JobParameters])

Each argument is described in detail in: L<Paws::Glacier::InitiateJob>

Returns: a L<Paws::Glacier::InitiateJobOutput> instance

  

This operation initiates a job of the specified type. In this release,
you can initiate a job to retrieve either an archive or a vault
inventory (a list of archives in a vault).

Retrieving data from Amazon Glacier is a two-step process:

=over

=item 1.

Initiate a retrieval job.

A data retrieval policy can cause your initiate retrieval job request
to fail with a PolicyEnforcedException exception. For more information
about data retrieval policies, see Amazon Glacier Data Retrieval
Policies. For more information about the PolicyEnforcedException
exception, see Error Responses.

=item 2.

After the job completes, download the bytes.

=back

The retrieval request is executed asynchronously. When you initiate a
retrieval job, Amazon Glacier creates a job and returns a job ID in the
response. When Amazon Glacier completes the job, you can get the job
output (archive or inventory data). For information about getting job
output, see GetJobOutput operation.

The job must complete before you can get its output. To determine when
a job is complete, you have the following options:

=over

=item *

B<Use Amazon SNS Notification> You can specify an Amazon Simple
Notification Service (Amazon SNS) topic to which Amazon Glacier can
post a notification after the job is completed. You can specify an SNS
topic per job request. The notification is sent only after Amazon
Glacier completes the job. In addition to specifying an SNS topic per
job request, you can configure vault notifications for a vault so that
job notifications are always sent. For more information, see
SetVaultNotifications.

=item *

B<Get job details> You can make a DescribeJob request to obtain job
status information while a job is in progress. However, it is more
efficient to use an Amazon SNS notification to determine when a job is
complete.

=back

The information you get via notification is same that you get by
calling DescribeJob.

If for a specific event, you add both the notification configuration on
the vault and also specify an SNS topic in your initiate job request,
Amazon Glacier sends both notifications. For more information, see
SetVaultNotifications.

An AWS account has full permission to perform all operations (actions).
However, AWS Identity and Access Management (IAM) users don't have any
permissions by default. You must grant them explicit permission to
perform specific actions. For more information, see Access Control
Using AWS Identity and Access Management (IAM).

B<About the Vault Inventory>

Amazon Glacier prepares an inventory for each vault periodically, every
24 hours. When you initiate a job for a vault inventory, Amazon Glacier
returns the last inventory for the vault. The inventory data you get
might be up to a day or two days old. Also, the initiate inventory job
might take some time to complete before you can download the vault
inventory. So you do not want to retrieve a vault inventory for each
vault operation. However, in some scenarios, you might find the vault
inventory useful. For example, when you upload an archive, you can
provide an archive description but not an archive name. Amazon Glacier
provides you a unique archive ID, an opaque string of characters. So,
you might maintain your own database that maps archive names to their
corresponding Amazon Glacier assigned archive IDs. You might find the
vault inventory useful in the event you need to reconcile information
in your database with the actual vault inventory.

B<Range Inventory Retrieval>

You can limit the number of inventory items retrieved by filtering on
the archive creation date or by setting a limit.

I<Filtering by Archive Creation Date>

You can retrieve inventory items for archives created between
C<StartDate> and C<EndDate> by specifying values for these parameters
in the B<InitiateJob> request. Archives created on or after the
C<StartDate> and before the C<EndDate> will be returned. If you only
provide the C<StartDate> without the C<EndDate>, you will retrieve the
inventory for all archives created on or after the C<StartDate>. If you
only provide the C<EndDate> without the C<StartDate>, you will get back
the inventory for all archives created before the C<EndDate>.

I<Limiting Inventory Items per Retrieval>

You can limit the number of inventory items returned by setting the
C<Limit> parameter in the B<InitiateJob> request. The inventory job
output will contain inventory items up to the specified C<Limit>. If
there are more inventory items available, the result is paginated.
After a job is complete you can use the DescribeJob operation to get a
marker that you use in a subsequent B<InitiateJob> request. The marker
will indicate the starting point to retrieve the next set of inventory
items. You can page through your entire inventory by repeatedly making
B<InitiateJob> requests with the marker from the previous
B<DescribeJob> output, until you get a marker from B<DescribeJob> that
returns null, indicating that there are no more inventory items
available.

You can use the C<Limit> parameter together with the date range
parameters.

B<About Ranged Archive Retrieval>

You can initiate an archive retrieval for the whole archive or a range
of the archive. In the case of ranged archive retrieval, you specify a
byte range to return or the whole archive. The range specified must be
megabyte (MB) aligned, that is the range start value must be divisible
by 1 MB and range end value plus 1 must be divisible by 1 MB or equal
the end of the archive. If the ranged archive retrieval is not megabyte
aligned, this operation returns a 400 response. Furthermore, to ensure
you get checksum values for data you download using Get Job Output API,
the range must be tree hash aligned.

An AWS account has full permission to perform all operations (actions).
However, AWS Identity and Access Management (IAM) users don't have any
permissions by default. You must grant them explicit permission to
perform specific actions. For more information, see Access Control
Using AWS Identity and Access Management (IAM).

For conceptual information and the underlying REST API, go to Initiate
a Job and Downloading a Vault Inventory











=head2 InitiateMultipartUpload(accountId => Str, vaultName => Str, [archiveDescription => Str, partSize => Str])

Each argument is described in detail in: L<Paws::Glacier::InitiateMultipartUpload>

Returns: a L<Paws::Glacier::InitiateMultipartUploadOutput> instance

  

This operation initiates a multipart upload. Amazon Glacier creates a
multipart upload resource and returns its ID in the response. The
multipart upload ID is used in subsequent requests to upload parts of
an archive (see UploadMultipartPart).

When you initiate a multipart upload, you specify the part size in
number of bytes. The part size must be a megabyte (1024 KB) multiplied
by a power of 2-for example, 1048576 (1 MB), 2097152 (2 MB), 4194304 (4
MB), 8388608 (8 MB), and so on. The minimum allowable part size is 1
MB, and the maximum is 4 GB.

Every part you upload to this resource (see UploadMultipartPart),
except the last one, must have the same size. The last one can be the
same size or smaller. For example, suppose you want to upload a 16.2 MB
file. If you initiate the multipart upload with a part size of 4 MB,
you will upload four parts of 4 MB each and one part of 0.2 MB.

You don't need to know the size of the archive when you start a
multipart upload because Amazon Glacier does not require you to specify
the overall archive size.

After you complete the multipart upload, Amazon Glacier removes the
multipart upload resource referenced by the ID. Amazon Glacier also
removes the multipart upload resource if you cancel the multipart
upload or it may be removed if there is no activity for a period of 24
hours.

An AWS account has full permission to perform all operations (actions).
However, AWS Identity and Access Management (IAM) users don't have any
permissions by default. You must grant them explicit permission to
perform specific actions. For more information, see Access Control
Using AWS Identity and Access Management (IAM).

For conceptual information and underlying REST API, go to Uploading
Large Archives in Parts (Multipart Upload) and Initiate Multipart
Upload in the I<Amazon Glacier Developer Guide>.











=head2 ListJobs(accountId => Str, vaultName => Str, [completed => Str, limit => Str, marker => Str, statuscode => Str])

Each argument is described in detail in: L<Paws::Glacier::ListJobs>

Returns: a L<Paws::Glacier::ListJobsOutput> instance

  

This operation lists jobs for a vault, including jobs that are
in-progress and jobs that have recently finished.

Amazon Glacier retains recently completed jobs for a period before
deleting them; however, it eventually removes completed jobs. The
output of completed jobs can be retrieved. Retaining completed jobs for
a period of time after they have completed enables you to get a job
output in the event you miss the job completion notification or your
first attempt to download it fails. For example, suppose you start an
archive retrieval job to download an archive. After the job completes,
you start to download the archive but encounter a network error. In
this scenario, you can retry and download the archive while the job
exists.

To retrieve an archive or retrieve a vault inventory from Amazon
Glacier, you first initiate a job, and after the job completes, you
download the data. For an archive retrieval, the output is the archive
data, and for an inventory retrieval, it is the inventory list. The
List Job operation returns a list of these jobs sorted by job
initiation time.

This List Jobs operation supports pagination. By default, this
operation returns up to 1,000 jobs in the response. You should always
check the response for a C<marker> at which to continue the list; if
there are no more items the C<marker> is C<null>. To return a list of
jobs that begins at a specific job, set the C<marker> request parameter
to the value you obtained from a previous List Jobs request. You can
also limit the number of jobs returned in the response by specifying
the C<limit> parameter in the request.

Additionally, you can filter the jobs list returned by specifying an
optional C<statuscode> (InProgress, Succeeded, or Failed) and
C<completed> (true, false) parameter. The C<statuscode> allows you to
specify that only jobs that match a specified status are returned. The
C<completed> parameter allows you to specify that only jobs in a
specific completion state are returned.

An AWS account has full permission to perform all operations (actions).
However, AWS Identity and Access Management (IAM) users don't have any
permissions by default. You must grant them explicit permission to
perform specific actions. For more information, see Access Control
Using AWS Identity and Access Management (IAM).

For the underlying REST API, go to List Jobs











=head2 ListMultipartUploads(accountId => Str, vaultName => Str, [limit => Str, marker => Str])

Each argument is described in detail in: L<Paws::Glacier::ListMultipartUploads>

Returns: a L<Paws::Glacier::ListMultipartUploadsOutput> instance

  

This operation lists in-progress multipart uploads for the specified
vault. An in-progress multipart upload is a multipart upload that has
been initiated by an InitiateMultipartUpload request, but has not yet
been completed or aborted. The list returned in the List Multipart
Upload response has no guaranteed order.

The List Multipart Uploads operation supports pagination. By default,
this operation returns up to 1,000 multipart uploads in the response.
You should always check the response for a C<marker> at which to
continue the list; if there are no more items the C<marker> is C<null>.
To return a list of multipart uploads that begins at a specific upload,
set the C<marker> request parameter to the value you obtained from a
previous List Multipart Upload request. You can also limit the number
of uploads returned in the response by specifying the C<limit>
parameter in the request.

Note the difference between this operation and listing parts
(ListParts). The List Multipart Uploads operation lists all multipart
uploads for a vault and does not require a multipart upload ID. The
List Parts operation requires a multipart upload ID since parts are
associated with a single upload.

An AWS account has full permission to perform all operations (actions).
However, AWS Identity and Access Management (IAM) users don't have any
permissions by default. You must grant them explicit permission to
perform specific actions. For more information, see Access Control
Using AWS Identity and Access Management (IAM).

For conceptual information and the underlying REST API, go to Working
with Archives in Amazon Glacier and List Multipart Uploads in the
I<Amazon Glacier Developer Guide>.











=head2 ListParts(accountId => Str, uploadId => Str, vaultName => Str, [limit => Str, marker => Str])

Each argument is described in detail in: L<Paws::Glacier::ListParts>

Returns: a L<Paws::Glacier::ListPartsOutput> instance

  

This operation lists the parts of an archive that have been uploaded in
a specific multipart upload. You can make this request at any time
during an in-progress multipart upload before you complete the upload
(see CompleteMultipartUpload. List Parts returns an error for completed
uploads. The list returned in the List Parts response is sorted by part
range.

The List Parts operation supports pagination. By default, this
operation returns up to 1,000 uploaded parts in the response. You
should always check the response for a C<marker> at which to continue
the list; if there are no more items the C<marker> is C<null>. To
return a list of parts that begins at a specific part, set the
C<marker> request parameter to the value you obtained from a previous
List Parts request. You can also limit the number of parts returned in
the response by specifying the C<limit> parameter in the request.

An AWS account has full permission to perform all operations (actions).
However, AWS Identity and Access Management (IAM) users don't have any
permissions by default. You must grant them explicit permission to
perform specific actions. For more information, see Access Control
Using AWS Identity and Access Management (IAM).

For conceptual information and the underlying REST API, go to Working
with Archives in Amazon Glacier and List Parts in the I<Amazon Glacier
Developer Guide>.











=head2 ListTagsForVault(accountId => Str, vaultName => Str)

Each argument is described in detail in: L<Paws::Glacier::ListTagsForVault>

Returns: a L<Paws::Glacier::ListTagsForVaultOutput> instance

  

This operation lists all the tags attached to a vault. The operation
returns an empty map if there are no tags. For more information about
tags, see Tagging Amazon Glacier Resources.











=head2 ListVaults(accountId => Str, [limit => Str, marker => Str])

Each argument is described in detail in: L<Paws::Glacier::ListVaults>

Returns: a L<Paws::Glacier::ListVaultsOutput> instance

  

This operation lists all vaults owned by the calling user's account.
The list returned in the response is ASCII-sorted by vault name.

By default, this operation returns up to 1,000 items. If there are more
vaults to list, the response C<marker> field contains the vault Amazon
Resource Name (ARN) at which to continue the list with a new List
Vaults request; otherwise, the C<marker> field is C<null>. To return a
list of vaults that begins at a specific vault, set the C<marker>
request parameter to the vault ARN you obtained from a previous List
Vaults request. You can also limit the number of vaults returned in the
response by specifying the C<limit> parameter in the request.

An AWS account has full permission to perform all operations (actions).
However, AWS Identity and Access Management (IAM) users don't have any
permissions by default. You must grant them explicit permission to
perform specific actions. For more information, see Access Control
Using AWS Identity and Access Management (IAM).

For conceptual information and underlying REST API, go to Retrieving
Vault Metadata in Amazon Glacier and List Vaults in the I<Amazon
Glacier Developer Guide>.











=head2 RemoveTagsFromVault(accountId => Str, vaultName => Str, [TagKeys => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::Glacier::RemoveTagsFromVault>

Returns: nothing

  

This operation removes one or more tags from the set of tags attached
to a vault. For more information about tags, see Tagging Amazon Glacier
Resources. This operation is idempotent. The operation will be
successful, even if there are no tags attached to the vault.











=head2 SetDataRetrievalPolicy(accountId => Str, [Policy => Paws::Glacier::DataRetrievalPolicy])

Each argument is described in detail in: L<Paws::Glacier::SetDataRetrievalPolicy>

Returns: nothing

  

This operation sets and then enacts a data retrieval policy in the
region specified in the PUT request. You can set one policy per region
for an AWS account. The policy is enacted within a few minutes of a
successful PUT operation.

The set policy operation does not affect retrieval jobs that were in
progress before the policy was enacted. For more information about data
retrieval policies, see Amazon Glacier Data Retrieval Policies.











=head2 SetVaultAccessPolicy(accountId => Str, vaultName => Str, [policy => Paws::Glacier::VaultAccessPolicy])

Each argument is described in detail in: L<Paws::Glacier::SetVaultAccessPolicy>

Returns: nothing

  

This operation configures an access policy for a vault and will
overwrite an existing policy. To configure a vault access policy, send
a PUT request to the C<access-policy> subresource of the vault. An
access policy is specific to a vault and is also called a vault
subresource. You can set one access policy per vault and the policy can
be up to 20 KB in size. For more information about vault access
policies, see Amazon Glacier Access Control with Vault Access Policies.











=head2 SetVaultNotifications(accountId => Str, vaultName => Str, [vaultNotificationConfig => Paws::Glacier::VaultNotificationConfig])

Each argument is described in detail in: L<Paws::Glacier::SetVaultNotifications>

Returns: nothing

  

This operation configures notifications that will be sent when specific
events happen to a vault. By default, you don't get any notifications.

To configure vault notifications, send a PUT request to the
C<notification-configuration> subresource of the vault. The request
should include a JSON document that provides an Amazon SNS topic and
specific events for which you want Amazon Glacier to send notifications
to the topic.

Amazon SNS topics must grant permission to the vault to be allowed to
publish notifications to the topic. You can configure a vault to
publish a notification for the following vault events:

=over

=item * B<ArchiveRetrievalCompleted> This event occurs when a job that
was initiated for an archive retrieval is completed (InitiateJob). The
status of the completed job can be "Succeeded" or "Failed". The
notification sent to the SNS topic is the same output as returned from
DescribeJob.

=item * B<InventoryRetrievalCompleted> This event occurs when a job
that was initiated for an inventory retrieval is completed
(InitiateJob). The status of the completed job can be "Succeeded" or
"Failed". The notification sent to the SNS topic is the same output as
returned from DescribeJob.

=back

An AWS account has full permission to perform all operations (actions).
However, AWS Identity and Access Management (IAM) users don't have any
permissions by default. You must grant them explicit permission to
perform specific actions. For more information, see Access Control
Using AWS Identity and Access Management (IAM).

For conceptual information and underlying REST API, go to Configuring
Vault Notifications in Amazon Glacier and Set Vault Notification
Configuration in the I<Amazon Glacier Developer Guide>.











=head2 UploadArchive(accountId => Str, vaultName => Str, [archiveDescription => Str, body => Str, checksum => Str])

Each argument is described in detail in: L<Paws::Glacier::UploadArchive>

Returns: a L<Paws::Glacier::ArchiveCreationOutput> instance

  

This operation adds an archive to a vault. This is a synchronous
operation, and for a successful upload, your data is durably persisted.
Amazon Glacier returns the archive ID in the C<x-amz-archive-id> header
of the response.

You must use the archive ID to access your data in Amazon Glacier.
After you upload an archive, you should save the archive ID returned so
that you can retrieve or delete the archive later. Besides saving the
archive ID, you can also index it and give it a friendly name to allow
for better searching. You can also use the optional archive description
field to specify how the archive is referred to in an external index of
archives, such as you might create in Amazon DynamoDB. You can also get
the vault inventory to obtain a list of archive IDs in a vault. For
more information, see InitiateJob.

You must provide a SHA256 tree hash of the data you are uploading. For
information about computing a SHA256 tree hash, see Computing
Checksums.

You can optionally specify an archive description of up to 1,024
printable ASCII characters. You can get the archive description when
you either retrieve the archive or get the vault inventory. For more
information, see InitiateJob. Amazon Glacier does not interpret the
description in any way. An archive description does not need to be
unique. You cannot use the description to retrieve or sort the archive
list.

Archives are immutable. After you upload an archive, you cannot edit
the archive or its description.

An AWS account has full permission to perform all operations (actions).
However, AWS Identity and Access Management (IAM) users don't have any
permissions by default. You must grant them explicit permission to
perform specific actions. For more information, see Access Control
Using AWS Identity and Access Management (IAM).

For conceptual information and underlying REST API, go to Uploading an
Archive in Amazon Glacier and Upload Archive in the I<Amazon Glacier
Developer Guide>.











=head2 UploadMultipartPart(accountId => Str, uploadId => Str, vaultName => Str, [body => Str, checksum => Str, range => Str])

Each argument is described in detail in: L<Paws::Glacier::UploadMultipartPart>

Returns: a L<Paws::Glacier::UploadMultipartPartOutput> instance

  

This operation uploads a part of an archive. You can upload archive
parts in any order. You can also upload them in parallel. You can
upload up to 10,000 parts for a multipart upload.

Amazon Glacier rejects your upload part request if any of the following
conditions is true:

=over

=item *

B<SHA256 tree hash does not match>To ensure that part data is not
corrupted in transmission, you compute a SHA256 tree hash of the part
and include it in your request. Upon receiving the part data, Amazon
Glacier also computes a SHA256 tree hash. If these hash values don't
match, the operation fails. For information about computing a SHA256
tree hash, see Computing Checksums.

=item *

B<Part size does not match>The size of each part except the last must
match the size specified in the corresponding InitiateMultipartUpload
request. The size of the last part must be the same size as, or smaller
than, the specified size.

If you upload a part whose size is smaller than the part size you
specified in your initiate multipart upload request and that part is
not the last part, then the upload part request will succeed. However,
the subsequent Complete Multipart Upload request will fail.

=item * B<Range does not align>The byte range value in the request does
not align with the part size specified in the corresponding initiate
request. For example, if you specify a part size of 4194304 bytes (4
MB), then 0 to 4194303 bytes (4 MB - 1) and 4194304 (4 MB) to 8388607
(8 MB - 1) are valid part ranges. However, if you set a range value of
2 MB to 6 MB, the range does not align with the part size and the
upload will fail.

=back

This operation is idempotent. If you upload the same part multiple
times, the data included in the most recent request overwrites the
previously uploaded data.

An AWS account has full permission to perform all operations (actions).
However, AWS Identity and Access Management (IAM) users don't have any
permissions by default. You must grant them explicit permission to
perform specific actions. For more information, see Access Control
Using AWS Identity and Access Management (IAM).

For conceptual information and underlying REST API, go to Uploading
Large Archives in Parts (Multipart Upload) and Upload Part in the
I<Amazon Glacier Developer Guide>.











=head1 SEE ALSO

This service class forms part of L<Paws>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

