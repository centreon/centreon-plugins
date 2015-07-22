package Paws::WorkSpaces {
  use Moose;
  sub service { 'workspaces' }
  sub version { '2015-04-08' }
  sub target_prefix { 'WorkspacesService' }
  sub json_version { "1.1" }

  with 'Paws::API::Caller', 'Paws::API::EndpointResolver', 'Paws::Net::V4Signature', 'Paws::Net::JsonCaller', 'Paws::Net::JsonResponse';

  
  sub CreateWorkspaces {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::WorkSpaces::CreateWorkspaces', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeWorkspaceBundles {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::WorkSpaces::DescribeWorkspaceBundles', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeWorkspaceDirectories {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::WorkSpaces::DescribeWorkspaceDirectories', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeWorkspaces {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::WorkSpaces::DescribeWorkspaces', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RebootWorkspaces {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::WorkSpaces::RebootWorkspaces', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RebuildWorkspaces {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::WorkSpaces::RebuildWorkspaces', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub TerminateWorkspaces {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::WorkSpaces::TerminateWorkspaces', @_);
    return $self->caller->do_call($self, $call_object);
  }
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::WorkSpaces - Perl Interface to AWS Amazon WorkSpaces

=head1 SYNOPSIS

  use Paws;

  my $obj = Paws->service('WorkSpaces')->new;
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



Amazon WorkSpaces Service

This is the I<Amazon WorkSpaces API Reference>. This guide provides
detailed information about Amazon WorkSpaces operations, data types,
parameters, and errors.










=head1 METHODS

=head2 CreateWorkspaces(Workspaces => ArrayRef[Paws::WorkSpaces::WorkspaceRequest])

Each argument is described in detail in: L<Paws::WorkSpaces::CreateWorkspaces>

Returns: a L<Paws::WorkSpaces::CreateWorkspacesResult> instance

  

Creates one or more WorkSpaces.

This operation is asynchronous and returns before the WorkSpaces are
created.











=head2 DescribeWorkspaceBundles([BundleIds => ArrayRef[Str], NextToken => Str, Owner => Str])

Each argument is described in detail in: L<Paws::WorkSpaces::DescribeWorkspaceBundles>

Returns: a L<Paws::WorkSpaces::DescribeWorkspaceBundlesResult> instance

  

Obtains information about the WorkSpace bundles that are available to
your account in the specified region.

You can filter the results with either the C<BundleIds> parameter, or
the C<Owner> parameter, but not both.

This operation supports pagination with the use of the C<NextToken>
request and response parameters. If more results are available, the
C<NextToken> response member contains a token that you pass in the next
call to this operation to retrieve the next set of items.











=head2 DescribeWorkspaceDirectories([DirectoryIds => ArrayRef[Str], NextToken => Str])

Each argument is described in detail in: L<Paws::WorkSpaces::DescribeWorkspaceDirectories>

Returns: a L<Paws::WorkSpaces::DescribeWorkspaceDirectoriesResult> instance

  

Retrieves information about the AWS Directory Service directories in
the region that are registered with Amazon WorkSpaces and are available
to your account.

This operation supports pagination with the use of the C<NextToken>
request and response parameters. If more results are available, the
C<NextToken> response member contains a token that you pass in the next
call to this operation to retrieve the next set of items.











=head2 DescribeWorkspaces([BundleId => Str, DirectoryId => Str, Limit => Int, NextToken => Str, UserName => Str, WorkspaceIds => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::WorkSpaces::DescribeWorkspaces>

Returns: a L<Paws::WorkSpaces::DescribeWorkspacesResult> instance

  

Obtains information about the specified WorkSpaces.

Only one of the filter parameters, such as C<BundleId>, C<DirectoryId>,
or C<WorkspaceIds>, can be specified at a time.

This operation supports pagination with the use of the C<NextToken>
request and response parameters. If more results are available, the
C<NextToken> response member contains a token that you pass in the next
call to this operation to retrieve the next set of items.











=head2 RebootWorkspaces(RebootWorkspaceRequests => ArrayRef[Paws::WorkSpaces::RebootRequest])

Each argument is described in detail in: L<Paws::WorkSpaces::RebootWorkspaces>

Returns: a L<Paws::WorkSpaces::RebootWorkspacesResult> instance

  

Reboots the specified WorkSpaces.

To be able to reboot a WorkSpace, the WorkSpace must have a B<State> of
C<AVAILABLE>, C<IMPAIRED>, or C<INOPERABLE>.

This operation is asynchronous and will return before the WorkSpaces
have rebooted.











=head2 RebuildWorkspaces(RebuildWorkspaceRequests => ArrayRef[Paws::WorkSpaces::RebuildRequest])

Each argument is described in detail in: L<Paws::WorkSpaces::RebuildWorkspaces>

Returns: a L<Paws::WorkSpaces::RebuildWorkspacesResult> instance

  

Rebuilds the specified WorkSpaces.

Rebuilding a WorkSpace is a potentially destructive action that can
result in the loss of data. Rebuilding a WorkSpace causes the following
to occur:

=over

=item * The system is restored to the image of the bundle that the
WorkSpace is created from. Any applications that have been installed,
or system settings that have been made since the WorkSpace was created
will be lost.

=item * The data drive (D drive) is re-created from the last automatic
snapshot taken of the data drive. The current contents of the data
drive are overwritten. Automatic snapshots of the data drive are taken
every 12 hours, so the snapshot can be as much as 12 hours old.

=back

To be able to rebuild a WorkSpace, the WorkSpace must have a B<State>
of C<AVAILABLE> or C<ERROR>.

This operation is asynchronous and will return before the WorkSpaces
have been completely rebuilt.











=head2 TerminateWorkspaces(TerminateWorkspaceRequests => ArrayRef[Paws::WorkSpaces::TerminateRequest])

Each argument is described in detail in: L<Paws::WorkSpaces::TerminateWorkspaces>

Returns: a L<Paws::WorkSpaces::TerminateWorkspacesResult> instance

  

Terminates the specified WorkSpaces.

Terminating a WorkSpace is a permanent action and cannot be undone. The
user's data is not maintained and will be destroyed. If you need to
archive any user data, contact Amazon Web Services before terminating
the WorkSpace.

You can terminate a WorkSpace that is in any state except C<SUSPENDED>.

This operation is asynchronous and will return before the WorkSpaces
have been completely terminated.











=head1 SEE ALSO

This service class forms part of L<Paws>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

