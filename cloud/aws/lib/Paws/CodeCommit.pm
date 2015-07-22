package Paws::CodeCommit {
  use Moose;
  sub service { 'codecommit' }
  sub version { '2015-04-13' }
  sub target_prefix { 'CodeCommit_20150413' }
  sub json_version { "1.1" }

  with 'Paws::API::Caller', 'Paws::API::EndpointResolver', 'Paws::Net::V4Signature', 'Paws::Net::JsonCaller', 'Paws::Net::JsonResponse';

  
  sub BatchGetRepositories {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CodeCommit::BatchGetRepositories', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateBranch {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CodeCommit::CreateBranch', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateRepository {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CodeCommit::CreateRepository', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteRepository {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CodeCommit::DeleteRepository', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetBranch {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CodeCommit::GetBranch', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetRepository {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CodeCommit::GetRepository', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListBranches {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CodeCommit::ListBranches', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListRepositories {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CodeCommit::ListRepositories', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateDefaultBranch {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CodeCommit::UpdateDefaultBranch', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateRepositoryDescription {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CodeCommit::UpdateRepositoryDescription', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateRepositoryName {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CodeCommit::UpdateRepositoryName', @_);
    return $self->caller->do_call($self, $call_object);
  }
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CodeCommit - Perl Interface to AWS AWS CodeCommit

=head1 SYNOPSIS

  use Paws;

  my $obj = Paws->service('CodeCommit')->new;
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



AWS CodeCommit

This is the I<AWS CodeCommit API Reference>. This reference provides
descriptions of the AWS CodeCommit API.

You can use the AWS CodeCommit API to work with the following objects:

=over

=item * Repositories

=item * Branches

=item * Commits

=back

For information about how to use AWS CodeCommit, see the I<AWS
CodeCommit User Guide>.










=head1 METHODS

=head2 BatchGetRepositories(repositoryNames => ArrayRef[Str])

Each argument is described in detail in: L<Paws::CodeCommit::BatchGetRepositories>

Returns: a L<Paws::CodeCommit::BatchGetRepositoriesOutput> instance

  

Gets information about one or more repositories.

The description field for a repository accepts all HTML characters and
all valid Unicode characters. Applications that do not HTML-encode the
description and display it in a web page could expose users to
potentially malicious code. Make sure that you HTML-encode the
description field in any application that uses this API to display the
repository description on a web page.











=head2 CreateBranch(branchName => Str, commitId => Str, repositoryName => Str)

Each argument is described in detail in: L<Paws::CodeCommit::CreateBranch>

Returns: nothing

  

Creates a new branch in a repository and points the branch to a commit.

Calling the create branch operation does not set a repository's default
branch. To do this, call the update default branch operation.











=head2 CreateRepository(repositoryName => Str, [repositoryDescription => Str])

Each argument is described in detail in: L<Paws::CodeCommit::CreateRepository>

Returns: a L<Paws::CodeCommit::CreateRepositoryOutput> instance

  

Creates a new, empty repository.











=head2 DeleteRepository(repositoryName => Str)

Each argument is described in detail in: L<Paws::CodeCommit::DeleteRepository>

Returns: a L<Paws::CodeCommit::DeleteRepositoryOutput> instance

  

Deletes a repository. If a specified repository was already deleted, a
null repository ID will be returned.

Deleting a repository also deletes all associated objects and metadata.
After a repository is deleted, all future push calls to the deleted
repository will fail.











=head2 GetBranch([branchName => Str, repositoryName => Str])

Each argument is described in detail in: L<Paws::CodeCommit::GetBranch>

Returns: a L<Paws::CodeCommit::GetBranchOutput> instance

  

Retrieves information about a repository branch, including its name and
the last commit ID.











=head2 GetRepository(repositoryName => Str)

Each argument is described in detail in: L<Paws::CodeCommit::GetRepository>

Returns: a L<Paws::CodeCommit::GetRepositoryOutput> instance

  

Gets information about a repository.

The description field for a repository accepts all HTML characters and
all valid Unicode characters. Applications that do not HTML-encode the
description and display it in a web page could expose users to
potentially malicious code. Make sure that you HTML-encode the
description field in any application that uses this API to display the
repository description on a web page.











=head2 ListBranches(repositoryName => Str, [nextToken => Str])

Each argument is described in detail in: L<Paws::CodeCommit::ListBranches>

Returns: a L<Paws::CodeCommit::ListBranchesOutput> instance

  

Gets information about one or more branches in a repository.











=head2 ListRepositories([nextToken => Str, order => Str, sortBy => Str])

Each argument is described in detail in: L<Paws::CodeCommit::ListRepositories>

Returns: a L<Paws::CodeCommit::ListRepositoriesOutput> instance

  

Gets information about one or more repositories.











=head2 UpdateDefaultBranch(defaultBranchName => Str, repositoryName => Str)

Each argument is described in detail in: L<Paws::CodeCommit::UpdateDefaultBranch>

Returns: nothing

  

Sets or changes the default branch name for the specified repository.

If you use this operation to change the default branch name to the
current default branch name, a success message is returned even though
the default branch did not change.











=head2 UpdateRepositoryDescription(repositoryName => Str, [repositoryDescription => Str])

Each argument is described in detail in: L<Paws::CodeCommit::UpdateRepositoryDescription>

Returns: nothing

  

Sets or changes the comment or description for a repository.

The description field for a repository accepts all HTML characters and
all valid Unicode characters. Applications that do not HTML-encode the
description and display it in a web page could expose users to
potentially malicious code. Make sure that you HTML-encode the
description field in any application that uses this API to display the
repository description on a web page.











=head2 UpdateRepositoryName(newName => Str, oldName => Str)

Each argument is described in detail in: L<Paws::CodeCommit::UpdateRepositoryName>

Returns: nothing

  

Renames a repository.











=head1 SEE ALSO

This service class forms part of L<Paws>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

