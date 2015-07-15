
package Paws::ElasticTranscoder::CreatePipeline {
  use Moose;
  has AwsKmsKeyArn => (is => 'ro', isa => 'Str');
  has ContentConfig => (is => 'ro', isa => 'Paws::ElasticTranscoder::PipelineOutputConfig');
  has InputBucket => (is => 'ro', isa => 'Str', required => 1);
  has Name => (is => 'ro', isa => 'Str', required => 1);
  has Notifications => (is => 'ro', isa => 'Paws::ElasticTranscoder::Notifications');
  has OutputBucket => (is => 'ro', isa => 'Str');
  has Role => (is => 'ro', isa => 'Str', required => 1);
  has ThumbnailConfig => (is => 'ro', isa => 'Paws::ElasticTranscoder::PipelineOutputConfig');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreatePipeline');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2012-09-25/pipelines');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'POST');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElasticTranscoder::CreatePipelineResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'CreatePipelineResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticTranscoder::CreatePipeline - Arguments for method CreatePipeline on Paws::ElasticTranscoder

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreatePipeline on the 
Amazon Elastic Transcoder service. Use the attributes of this class
as arguments to method CreatePipeline.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreatePipeline.

As an example:

  $service_obj->CreatePipeline(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AwsKmsKeyArn => Str

  

The AWS Key Management Service (AWS KMS) key that you want to use with
this pipeline.

If you use either C<S3> or C<S3-AWS-KMS> as your C<Encryption:Mode>,
you don't need to provide a key with your job because a default key,
known as an AWS-KMS key, is created for you automatically. You need to
provide an AWS-KMS key only if you want to use a non-default AWS-KMS
key, or if you are using an C<Encryption:Mode> of C<AES-PKCS7>,
C<AES-CTR>, or C<AES-GCM>.










=head2 ContentConfig => Paws::ElasticTranscoder::PipelineOutputConfig

  

The optional C<ContentConfig> object specifies information about the
Amazon S3 bucket in which you want Elastic Transcoder to save
transcoded files and playlists: which bucket to use, which users you
want to have access to the files, the type of access you want users to
have, and the storage class that you want to assign to the files.

If you specify values for C<ContentConfig>, you must also specify
values for C<ThumbnailConfig>.

If you specify values for C<ContentConfig> and C<ThumbnailConfig>, omit
the C<OutputBucket> object.

=over

=item * B<Bucket>: The Amazon S3 bucket in which you want Elastic
Transcoder to save transcoded files and playlists.

=item * B<Permissions> (Optional): The Permissions object specifies
which users you want to have access to transcoded files and the type of
access you want them to have. You can grant permissions to a maximum of
30 users and/or predefined Amazon S3 groups.

=item * B<Grantee Type>: Specify the type of value that appears in the
C<Grantee> object:

=over

=item * B<Canonical>: The value in the C<Grantee> object is either the
canonical user ID for an AWS account or an origin access identity for
an Amazon CloudFront distribution. For more information about canonical
user IDs, see Access Control List (ACL) Overview in the Amazon Simple
Storage Service Developer Guide. For more information about using
CloudFront origin access identities to require that users use
CloudFront URLs instead of Amazon S3 URLs, see Using an Origin Access
Identity to Restrict Access to Your Amazon S3 Content. A canonical user
ID is not the same as an AWS account number.

=item * B<Email>: The value in the C<Grantee> object is the registered
email address of an AWS account.

=item * B<Group>: The value in the C<Grantee> object is one of the
following predefined Amazon S3 groups: C<AllUsers>,
C<AuthenticatedUsers>, or C<LogDelivery>.

=back

=item * B<Grantee>: The AWS user or group that you want to have access
to transcoded files and playlists. To identify the user or group, you
can specify the canonical user ID for an AWS account, an origin access
identity for a CloudFront distribution, the registered email address of
an AWS account, or a predefined Amazon S3 group

=item * B<Access>: The permission that you want to give to the AWS user
that you specified in C<Grantee>. Permissions are granted on the files
that Elastic Transcoder adds to the bucket, including playlists and
video files. Valid values include:

=over

=item * C<READ>: The grantee can read the objects and metadata for
objects that Elastic Transcoder adds to the Amazon S3 bucket.

=item * C<READ_ACP>: The grantee can read the object ACL for objects
that Elastic Transcoder adds to the Amazon S3 bucket.

=item * C<WRITE_ACP>: The grantee can write the ACL for the objects
that Elastic Transcoder adds to the Amazon S3 bucket.

=item * C<FULL_CONTROL>: The grantee has C<READ>, C<READ_ACP>, and
C<WRITE_ACP> permissions for the objects that Elastic Transcoder adds
to the Amazon S3 bucket.

=back

=item * B<StorageClass>: The Amazon S3 storage class, C<Standard> or
C<ReducedRedundancy>, that you want Elastic Transcoder to assign to the
video files and playlists that it stores in your Amazon S3 bucket.

=back










=head2 B<REQUIRED> InputBucket => Str

  

The Amazon S3 bucket in which you saved the media files that you want
to transcode.










=head2 B<REQUIRED> Name => Str

  

The name of the pipeline. We recommend that the name be unique within
the AWS account, but uniqueness is not enforced.

Constraints: Maximum 40 characters.










=head2 Notifications => Paws::ElasticTranscoder::Notifications

  

The Amazon Simple Notification Service (Amazon SNS) topic that you want
to notify to report job status.

To receive notifications, you must also subscribe to the new topic in
the Amazon SNS console.

=over

=item * B<Progressing>: The topic ARN for the Amazon Simple
Notification Service (Amazon SNS) topic that you want to notify when
Elastic Transcoder has started to process a job in this pipeline. This
is the ARN that Amazon SNS returned when you created the topic. For
more information, see Create a Topic in the Amazon Simple Notification
Service Developer Guide.

=item * B<Completed>: The topic ARN for the Amazon SNS topic that you
want to notify when Elastic Transcoder has finished processing a job in
this pipeline. This is the ARN that Amazon SNS returned when you
created the topic.

=item * B<Warning>: The topic ARN for the Amazon SNS topic that you
want to notify when Elastic Transcoder encounters a warning condition
while processing a job in this pipeline. This is the ARN that Amazon
SNS returned when you created the topic.

=item * B<Error>: The topic ARN for the Amazon SNS topic that you want
to notify when Elastic Transcoder encounters an error condition while
processing a job in this pipeline. This is the ARN that Amazon SNS
returned when you created the topic.

=back










=head2 OutputBucket => Str

  

The Amazon S3 bucket in which you want Elastic Transcoder to save the
transcoded files. (Use this, or use ContentConfig:Bucket plus
ThumbnailConfig:Bucket.)

Specify this value when all of the following are true:

=over

=item * You want to save transcoded files, thumbnails (if any), and
playlists (if any) together in one bucket.

=item * You do not want to specify the users or groups who have access
to the transcoded files, thumbnails, and playlists.

=item * You do not want to specify the permissions that Elastic
Transcoder grants to the files. When Elastic Transcoder saves files in
C<OutputBucket>, it grants full control over the files only to the AWS
account that owns the role that is specified by C<Role>.

=item * You want to associate the transcoded files and thumbnails with
the Amazon S3 Standard storage class.

=back

If you want to save transcoded files and playlists in one bucket and
thumbnails in another bucket, specify which users can access the
transcoded files or the permissions the users have, or change the
Amazon S3 storage class, omit C<OutputBucket> and specify values for
C<ContentConfig> and C<ThumbnailConfig> instead.










=head2 B<REQUIRED> Role => Str

  

The IAM Amazon Resource Name (ARN) for the role that you want Elastic
Transcoder to use to create the pipeline.










=head2 ThumbnailConfig => Paws::ElasticTranscoder::PipelineOutputConfig

  

The C<ThumbnailConfig> object specifies several values, including the
Amazon S3 bucket in which you want Elastic Transcoder to save thumbnail
files, which users you want to have access to the files, the type of
access you want users to have, and the storage class that you want to
assign to the files.

If you specify values for C<ContentConfig>, you must also specify
values for C<ThumbnailConfig> even if you don't want to create
thumbnails.

If you specify values for C<ContentConfig> and C<ThumbnailConfig>, omit
the C<OutputBucket> object.

=over

=item * B<Bucket>: The Amazon S3 bucket in which you want Elastic
Transcoder to save thumbnail files.

=item * B<Permissions> (Optional): The C<Permissions> object specifies
which users and/or predefined Amazon S3 groups you want to have access
to thumbnail files, and the type of access you want them to have. You
can grant permissions to a maximum of 30 users and/or predefined Amazon
S3 groups.

=item * B<GranteeType>: Specify the type of value that appears in the
Grantee object:

=over

=item * B<Canonical>: The value in the C<Grantee> object is either the
canonical user ID for an AWS account or an origin access identity for
an Amazon CloudFront distribution. A canonical user ID is not the same
as an AWS account number.

=item * B<Email>: The value in the C<Grantee> object is the registered
email address of an AWS account.

=item * B<Group>: The value in the C<Grantee> object is one of the
following predefined Amazon S3 groups: C<AllUsers>,
C<AuthenticatedUsers>, or C<LogDelivery>.

=back

=item * B<Grantee>: The AWS user or group that you want to have access
to thumbnail files. To identify the user or group, you can specify the
canonical user ID for an AWS account, an origin access identity for a
CloudFront distribution, the registered email address of an AWS
account, or a predefined Amazon S3 group.

=item * B<Access>: The permission that you want to give to the AWS user
that you specified in C<Grantee>. Permissions are granted on the
thumbnail files that Elastic Transcoder adds to the bucket. Valid
values include:

=over

=item * C<READ>: The grantee can read the thumbnails and metadata for
objects that Elastic Transcoder adds to the Amazon S3 bucket.

=item * C<READ_ACP>: The grantee can read the object ACL for thumbnails
that Elastic Transcoder adds to the Amazon S3 bucket.

=item * C<WRITE_ACP>: The grantee can write the ACL for the thumbnails
that Elastic Transcoder adds to the Amazon S3 bucket.

=item * C<FULL_CONTROL>: The grantee has C<READ>, C<READ_ACP>, and
C<WRITE_ACP> permissions for the thumbnails that Elastic Transcoder
adds to the Amazon S3 bucket.

=back

=item * B<StorageClass>: The Amazon S3 storage class, C<Standard> or
C<ReducedRedundancy>, that you want Elastic Transcoder to assign to the
thumbnails that it stores in your Amazon S3 bucket.

=back












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreatePipeline in L<Paws::ElasticTranscoder>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

