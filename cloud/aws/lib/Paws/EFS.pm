package Paws::EFS {
  warn "Paws::EFS is not stable / supported / entirely developed";
  use Moose;
  sub service { 'elasticfilesystem' }
  sub version { '2015-02-01' }
  sub flattened_arrays { 0 }

  with 'Paws::API::Caller', 'Paws::API::EndpointResolver', 'Paws::Net::V4Signature', 'Paws::Net::RestJsonCaller', 'Paws::Net::RestJsonResponse';

  
  sub CreateFileSystem {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EFS::CreateFileSystem', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateMountTarget {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EFS::CreateMountTarget', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateTags {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EFS::CreateTags', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteFileSystem {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EFS::DeleteFileSystem', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteMountTarget {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EFS::DeleteMountTarget', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteTags {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EFS::DeleteTags', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeFileSystems {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EFS::DescribeFileSystems', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeMountTargets {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EFS::DescribeMountTargets', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeMountTargetSecurityGroups {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EFS::DescribeMountTargetSecurityGroups', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeTags {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EFS::DescribeTags', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ModifyMountTargetSecurityGroups {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::EFS::ModifyMountTargetSecurityGroups', @_);
    return $self->caller->do_call($self, $call_object);
  }
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EFS - Perl Interface to AWS Amazon Elastic File System

=head1 SYNOPSIS

  use Paws;

  my $obj = Paws->service('EFS')->new;
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



Amazon Elastic File System










=head1 METHODS

=head2 CreateFileSystem(CreationToken => Str)

Each argument is described in detail in: L<Paws::EFS::CreateFileSystem>

Returns: a L<Paws::EFS::FileSystemDescription> instance

  

Creates a new, empty file system. The operation requires a creation
token in the request that Amazon EFS uses to ensure idempotent creation
(calling the operation with same creation token has no effect). If a
file system does not currently exist that is owned by the caller's AWS
account with the specified creation token, this operation does the
following:

=over

=item * Creates a new, empty file system. The file system will have an
Amazon EFS assigned ID, and an initial lifecycle state "creating".

=item * Returns with the description of the created file system.

=back

Otherwise, this operation returns a C<FileSystemAlreadyExists> error
with the ID of the existing file system.

For basic use cases, you can use a randomly generated UUID for the
creation token.

The idempotent operation allows you to retry a C<CreateFileSystem> call
without risk of creating an extra file system. This can happen when an
initial call fails in a way that leaves it uncertain whether or not a
file system was actually created. An example might be that a transport
level timeout occurred or your connection was reset. As long as you use
the same creation token, if the initial call had succeeded in creating
a file system, the client can learn of its existence from the
C<FileSystemAlreadyExists> error.

The C<CreateFileSystem> call returns while the file system's lifecycle
state is still "creating". You can check the file system creation
status by calling the DescribeFileSystems API, which among other things
returns the file system state.

After the file system is fully created, Amazon EFS sets its lifecycle
state to "available", at which point you can create one or more mount
targets for the file system (CreateMountTarget) in your VPC. You mount
your Amazon EFS file system on an EC2 instances in your VPC via the
mount target. For more information, see Amazon EFS: How it Works

This operation requires permission for the
C<elasticfilesystem:CreateFileSystem> action.











=head2 CreateMountTarget(FileSystemId => Str, SubnetId => Str, [IpAddress => Str, SecurityGroups => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EFS::CreateMountTarget>

Returns: a L<Paws::EFS::MountTargetDescription> instance

  

Creates a mount target for a file system. You can then mount the file
system on EC2 instances via the mount target.

You can create one mount target in each Availability Zone in your VPC.
All EC2 instances in a VPC within a given Availability Zone share a
single mount target for a given file system. If you have multiple
subnets in an Availability Zone, you create a mount target in one of
the subnets. EC2 instances do not need to be in the same subnet as the
mount target in order to access their file system. For more
information, see Amazon EFS: How it Works.

In the request, you also specify a file system ID for which you are
creating the mount target and the file system's lifecycle state must be
"available" (see DescribeFileSystems).

In the request, you also provide a subnet ID, which serves several
purposes:

=over

=item * It determines the VPC in which Amazon EFS creates the mount
target.

=item * It determines the Availability Zone in which Amazon EFS creates
the mount target.

=item * It determines the IP address range from which Amazon EFS
selects the IP address of the mount target if you don't specify an IP
address in the request.

=back

After creating the mount target, Amazon EFS returns a response that
includes, a C<MountTargetId> and an C<IpAddress>. You use this IP
address when mounting the file system in an EC2 instance. You can also
use the mount target's DNS name when mounting the file system. The EC2
instance on which you mount the file system via the mount target can
resolve the mount target's DNS name to its IP address. For more
information, see How it Works: Implementation Overview

Note that you can create mount targets for a file system in only one
VPC, and there can be only one mount target per Availability Zone. That
is, if the file system already has one or more mount targets created
for it, the request to add another mount target must meet the following
requirements:

=over

=item *

The subnet specified in the request must belong to the same VPC as the
subnets of the existing mount targets.

=item * The subnet specified in the request must not be in the same
Availability Zone as any of the subnets of the existing mount targets.

=back

If the request satisfies the requirements, Amazon EFS does the
following:

=over

=item * Creates a new mount target in the specified subnet.

=item * Also creates a new network interface in the subnet as follows:

=over

=item * If the request provides an C<IpAddress>, Amazon EFS assigns
that IP address to the network interface. Otherwise, Amazon EFS assigns
a free address in the subnet (in the same way that the Amazon EC2
C<CreateNetworkInterface> call does when a request does not specify a
primary private IP address).

=item * If the request provides C<SecurityGroups>, this network
interface is associated with those security groups. Otherwise, it
belongs to the default security group for the subnet's VPC.

=item * Assigns the description C<"Mount target I<fsmt-id> for file
system I<fs-id>"> where C<I<fsmt-id>> is the mount target ID, and
C<I<fs-id>> is the C<FileSystemId>.

=item * Sets the C<requesterManaged> property of the network interface
to "true", and the C<requesterId> value to "EFS".

=back

Each Amazon EFS mount target has one corresponding requestor-managed
EC2 network interface. After the network interface is created, Amazon
EFS sets the C<NetworkInterfaceId> field in the mount target's
description to the network interface ID, and the C<IpAddress> field to
its address. If network interface creation fails, the entire
C<CreateMountTarget> operation fails.

=back

The C<CreateMountTarget> call returns only after creating the network
interface, but while the mount target state is still "creating". You
can check the mount target creation status by calling the
DescribeFileSystems API, which among other things returns the mount
target state.

We recommend you create a mount target in each of the Availability
Zones. There are cost considerations for using a file system in an
Availability Zone through a mount target created in another
Availability Zone. For more information, go to Amazon EFS product
detail page. In addition, by always using a mount target local to the
instance's Availability Zone, you eliminate a partial failure scenario;
if the Availablity Zone in which your mount target is created goes
down, then you won't be able to access your file system through that
mount target.

This operation requires permission for the following action on the file
system:

=over

=item * C<elasticfilesystem:CreateMountTarget>

=back

This operation also requires permission for the following Amazon EC2
actions:

=over

=item * C<ec2:DescribeSubnets>

=item * C<ec2:DescribeNetworkInterfaces>

=item * C<ec2:CreateNetworkInterface>

=back











=head2 CreateTags(FileSystemId => Str, Tags => ArrayRef[Paws::EFS::Tag])

Each argument is described in detail in: L<Paws::EFS::CreateTags>

Returns: nothing

  

Creates or overwrites tags associated with a file system. Each tag is a
key-value pair. If a tag key specified in the request already exists on
the file system, this operation overwrites its value with the value
provided in the request. If you add the "Name" tag to your file system,
Amazon EFS returns it in the response to the DescribeFileSystems API.

This operation requires permission for the
C<elasticfilesystem:CreateTags> action.











=head2 DeleteFileSystem(FileSystemId => Str)

Each argument is described in detail in: L<Paws::EFS::DeleteFileSystem>

Returns: nothing

  

Deletes a file system, permanently severing access to its contents.
Upon return, the file system no longer exists and you will not be able
to access any contents of the deleted file system.

You cannot delete a file system that is in use. That is, if the file
system has any mount targets, you must first delete them. For more
information, see DescribeMountTargets and DeleteMountTarget.

The C<DeleteFileSystem> call returns while the file system state is
still "deleting". You can check the file system deletion status by
calling the DescribeFileSystems API, which returns a list of file
systems in your account. If you pass file system ID or creation token
for the deleted file system, the DescribeFileSystems will return a 404
"FileSystemNotFound" error.

This operation requires permission for the
C<elasticfilesystem:DeleteFileSystem> action.











=head2 DeleteMountTarget(MountTargetId => Str)

Each argument is described in detail in: L<Paws::EFS::DeleteMountTarget>

Returns: nothing

  

Deletes the specified mount target.

This operation forcibly breaks any mounts of the file system via the
mount target being deleted, which might disrupt instances or
applications using those mounts. To avoid applications getting cut off
abruptly, you might consider unmounting any mounts of the mount target,
if feasible. The operation also deletes the associated network
interface. Uncommitted writes may be lost, but breaking a mount target
using this operation does not corrupt the file system itself. The file
system you created remains. You can mount an EC2 instance in your VPC
using another mount target.

This operation requires permission for the following action on the file
system:

=over

=item * C<elasticfilesystem:DeleteMountTarget>

=back

The C<DeleteMountTarget> call returns while the mount target state is
still "deleting". You can check the mount target deletion by calling
the DescribeMountTargets API, which returns a list of mount target
descriptions for the given file system.

The operation also requires permission for the following Amazon EC2
action on the mount target's network interface:

=over

=item * C<ec2:DeleteNetworkInterface>

=back











=head2 DeleteTags(FileSystemId => Str, TagKeys => ArrayRef[Str])

Each argument is described in detail in: L<Paws::EFS::DeleteTags>

Returns: nothing

  

Deletes the specified tags from a file system. If the C<DeleteTags>
request includes a tag key that does not exist, Amazon EFS ignores it;
it is not an error. For more information about tags and related
restrictions, go to Tag Restrictions in the I<AWS Billing and Cost
Management User Guide>.

This operation requires permission for the
C<elasticfilesystem:DeleteTags> action.











=head2 DescribeFileSystems([CreationToken => Str, FileSystemId => Str, Marker => Str, MaxItems => Int])

Each argument is described in detail in: L<Paws::EFS::DescribeFileSystems>

Returns: a L<Paws::EFS::DescribeFileSystemsResponse> instance

  

Returns the description of a specific Amazon EFS file system if either
the file system C<CreationToken> or the C<FileSystemId> is provided;
otherwise, returns descriptions of all file systems owned by the
caller's AWS account in the AWS region of the endpoint that you're
calling.

When retrieving all file system descriptions, you can optionally
specify the C<MaxItems> parameter to limit the number of descriptions
in a response. If more file system descriptions remain, Amazon EFS
returns a C<NextMarker>, an opaque token, in the response. In this
case, you should send a subsequent request with the C<Marker> request
parameter set to the value of C<NextMarker>.

So to retrieve a list of your file system descriptions, the expected
usage of this API is an iterative process of first calling
C<DescribeFileSystems> without the C<Marker> and then continuing to
call it with the C<Marker> parameter set to the value of the
C<NextMarker> from the previous response until the response has no
C<NextMarker>.

Note that the implementation may return fewer than C<MaxItems> file
system descriptions while still including a C<NextMarker> value.

The order of file systems returned in the response of one
C<DescribeFileSystems> call, and the order of file systems returned
across the responses of a multi-call iteration, is unspecified.

This operation requires permission for the
C<elasticfilesystem:DescribeFileSystems> action.











=head2 DescribeMountTargets(FileSystemId => Str, [Marker => Str, MaxItems => Int])

Each argument is described in detail in: L<Paws::EFS::DescribeMountTargets>

Returns: a L<Paws::EFS::DescribeMountTargetsResponse> instance

  

Returns the descriptions of the current mount targets for a file
system. The order of mount targets returned in the response is
unspecified.

This operation requires permission for the
C<elasticfilesystem:DescribeMountTargets> action on the file system
C<FileSystemId>.











=head2 DescribeMountTargetSecurityGroups(MountTargetId => Str)

Each argument is described in detail in: L<Paws::EFS::DescribeMountTargetSecurityGroups>

Returns: a L<Paws::EFS::DescribeMountTargetSecurityGroupsResponse> instance

  

Returns the security groups currently in effect for a mount target.
This operation requires that the network interface of the mount target
has been created and the life cycle state of the mount target is not
"deleted".

This operation requires permissions for the following actions:

=over

=item * C<elasticfilesystem:DescribeMountTargetSecurityGroups> action
on the mount target's file system.

=item * C<ec2:DescribeNetworkInterfaceAttribute> action on the mount
target's network interface.

=back











=head2 DescribeTags(FileSystemId => Str, [Marker => Str, MaxItems => Int])

Each argument is described in detail in: L<Paws::EFS::DescribeTags>

Returns: a L<Paws::EFS::DescribeTagsResponse> instance

  

Returns the tags associated with a file system. The order of tags
returned in the response of one C<DescribeTags> call, and the order of
tags returned across the responses of a multi-call iteration (when
using pagination), is unspecified.

This operation requires permission for the
C<elasticfilesystem:DescribeTags> action.











=head2 ModifyMountTargetSecurityGroups(MountTargetId => Str, [SecurityGroups => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::EFS::ModifyMountTargetSecurityGroups>

Returns: nothing

  

Modifies the set of security groups in effect for a mount target.

When you create a mount target, Amazon EFS also creates a new network
interface (see CreateMountTarget). This operation replaces the security
groups in effect for the network interface associated with a mount
target, with the C<SecurityGroups> provided in the request. This
operation requires that the network interface of the mount target has
been created and the life cycle state of the mount target is not
"deleted".

The operation requires permissions for the following actions:

=over

=item * C<elasticfilesystem:ModifyMountTargetSecurityGroups> action on
the mount target's file system.

=item * C<ec2:ModifyNetworkInterfaceAttribute> action on the mount
target's network interface.

=back











=head1 SEE ALSO

This service class forms part of L<Paws>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

