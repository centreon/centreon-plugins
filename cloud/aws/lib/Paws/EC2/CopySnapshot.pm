
package Paws::EC2::CopySnapshot {
  use Moose;
  has Description => (is => 'ro', isa => 'Str');
  has DestinationRegion => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'destinationRegion' );
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has Encrypted => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'encrypted' );
  has KmsKeyId => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'kmsKeyId' );
  has PresignedUrl => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'presignedUrl' );
  has SourceRegion => (is => 'ro', isa => 'Str', required => 1);
  has SourceSnapshotId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CopySnapshot');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::CopySnapshotResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::CopySnapshot - Arguments for method CopySnapshot on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method CopySnapshot on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method CopySnapshot.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CopySnapshot.

As an example:

  $service_obj->CopySnapshot(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Description => Str

  

A description for the EBS snapshot.










=head2 DestinationRegion => Str

  

The destination region to use in the C<PresignedUrl> parameter of a
snapshot copy operation. This parameter is only valid for specifying
the destination region in a C<PresignedUrl> parameter, where it is
required.

C<CopySnapshot> sends the snapshot copy to the regional endpoint that
you send the HTTP request to, such as C<ec2.us-east-1.amazonaws.com>
(in the AWS CLI, this is specified with the C<--region> parameter or
the default region in your AWS configuration file).










=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 Encrypted => Bool

  

Specifies whether the destination snapshot should be encrypted. There
is no way to create an unencrypted snapshot copy from an encrypted
snapshot; however, you can encrypt a copy of an unencrypted snapshot
with this flag. The default CMK for EBS is used unless a non-default
AWS Key Management Service (KMS) CMK is specified with C<KmsKeyId>. For
more information, see Amazon EBS Encryption in the I<Amazon Elastic
Compute Cloud User Guide>.










=head2 KmsKeyId => Str

  

The full ARN of the AWS Key Management Service (KMS) CMK to use when
creating the snapshot copy. This parameter is only required if you want
to use a non-default CMK; if this parameter is not specified, the
default CMK for EBS is used. The ARN contains the C<arn:aws:kms>
namespace, followed by the region of the CMK, the AWS account ID of the
CMK owner, the C<key> namespace, and then the CMK ID. For example,
arn:aws:kms:I<us-east-1>:I<012345678910>:key/I<abcd1234-a123-456a-a12b-a123b4cd56ef>.
The specified CMK must exist in the region that the snapshot is being
copied to. If a C<KmsKeyId> is specified, the C<Encrypted> flag must
also be set.










=head2 PresignedUrl => Str

  

The pre-signed URL that facilitates copying an encrypted snapshot. This
parameter is only required when copying an encrypted snapshot with the
Amazon EC2 Query API; it is available as an optional parameter in all
other cases. The C<PresignedUrl> should use the snapshot source
endpoint, the C<CopySnapshot> action, and include the C<SourceRegion>,
C<SourceSnapshotId>, and C<DestinationRegion> parameters. The
C<PresignedUrl> must be signed using AWS Signature Version 4. Because
EBS snapshots are stored in Amazon S3, the signing algorithm for this
parameter uses the same logic that is described in Authenticating
Requests by Using Query Parameters (AWS Signature Version 4) in the
I<Amazon Simple Storage Service API Reference>. An invalid or
improperly signed C<PresignedUrl> will cause the copy operation to fail
asynchronously, and the snapshot will move to an C<error> state.










=head2 B<REQUIRED> SourceRegion => Str

  

The ID of the region that contains the snapshot to be copied.










=head2 B<REQUIRED> SourceSnapshotId => Str

  

The ID of the EBS snapshot to copy.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CopySnapshot in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

