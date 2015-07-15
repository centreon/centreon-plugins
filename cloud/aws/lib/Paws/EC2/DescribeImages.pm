
package Paws::EC2::DescribeImages {
  use Moose;
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has ExecutableUsers => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'ExecutableBy' );
  has Filters => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Filter]', traits => ['NameInRequest'], request_name => 'Filter' );
  has ImageIds => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'ImageId' );
  has Owners => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'Owner' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeImages');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::DescribeImagesResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeImages - Arguments for method DescribeImages on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeImages on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method DescribeImages.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeImages.

As an example:

  $service_obj->DescribeImages(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 ExecutableUsers => ArrayRef[Str]

  

Scopes the images by users with explicit launch permissions. Specify an
AWS account ID, C<self> (the sender of the request), or C<all> (public
AMIs).










=head2 Filters => ArrayRef[Paws::EC2::Filter]

  

One or more filters.

=over

=item *

C<architecture> - The image architecture (C<i386> | C<x86_64>).

=item *

C<block-device-mapping.delete-on-termination> - A Boolean value that
indicates whether the Amazon EBS volume is deleted on instance
termination.

=item *

C<block-device-mapping.device-name> - The device name for the EBS
volume (for example, C</dev/sdh>).

=item *

C<block-device-mapping.snapshot-id> - The ID of the snapshot used for
the EBS volume.

=item *

C<block-device-mapping.volume-size> - The volume size of the EBS
volume, in GiB.

=item *

C<block-device-mapping.volume-type> - The volume type of the EBS volume
(C<gp2> | C<standard> | C<io1>).

=item *

C<description> - The description of the image (provided during image
creation).

=item *

C<hypervisor> - The hypervisor type (C<ovm> | C<xen>).

=item *

C<image-id> - The ID of the image.

=item *

C<image-type> - The image type (C<machine> | C<kernel> | C<ramdisk>).

=item *

C<is-public> - A Boolean that indicates whether the image is public.

=item *

C<kernel-id> - The kernel ID.

=item *

C<manifest-location> - The location of the image manifest.

=item *

C<name> - The name of the AMI (provided during image creation).

=item *

C<owner-alias> - The AWS account alias (for example, C<amazon>).

=item *

C<owner-id> - The AWS account ID of the image owner.

=item *

C<platform> - The platform. To only list Windows-based AMIs, use
C<windows>.

=item *

C<product-code> - The product code.

=item *

C<product-code.type> - The type of the product code (C<devpay> |
C<marketplace>).

=item *

C<ramdisk-id> - The RAM disk ID.

=item *

C<root-device-name> - The name of the root device volume (for example,
C</dev/sda1>).

=item *

C<root-device-type> - The type of the root device volume (C<ebs> |
C<instance-store>).

=item *

C<state> - The state of the image (C<available> | C<pending> |
C<failed>).

=item *

C<state-reason-code> - The reason code for the state change.

=item *

C<state-reason-message> - The message for the state change.

=item *

C<tag>:I<key>=I<value> - The key/value combination of a tag assigned to
the resource.

=item *

C<tag-key> - The key of a tag assigned to the resource. This filter is
independent of the tag-value filter. For example, if you use both the
filter "tag-key=Purpose" and the filter "tag-value=X", you get any
resources assigned both the tag key Purpose (regardless of what the
tag's value is), and the tag value X (regardless of what the tag's key
is). If you want to list only resources where Purpose is X, see the
C<tag>:I<key>=I<value> filter.

=item *

C<tag-value> - The value of a tag assigned to the resource. This filter
is independent of the C<tag-key> filter.

=item *

C<virtualization-type> - The virtualization type (C<paravirtual> |
C<hvm>).

=back










=head2 ImageIds => ArrayRef[Str]

  

One or more image IDs.

Default: Describes all images available to you.










=head2 Owners => ArrayRef[Str]

  

Filters the images by the owner. Specify an AWS account ID, C<amazon>
(owner is Amazon), C<aws-marketplace> (owner is AWS Marketplace),
C<self> (owner is the sender of the request). Omitting this option
returns all images for which you have launch permissions, regardless of
ownership.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeImages in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

