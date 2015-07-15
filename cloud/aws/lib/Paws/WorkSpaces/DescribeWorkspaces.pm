
package Paws::WorkSpaces::DescribeWorkspaces {
  use Moose;
  has BundleId => (is => 'ro', isa => 'Str');
  has DirectoryId => (is => 'ro', isa => 'Str');
  has Limit => (is => 'ro', isa => 'Int');
  has NextToken => (is => 'ro', isa => 'Str');
  has UserName => (is => 'ro', isa => 'Str');
  has WorkspaceIds => (is => 'ro', isa => 'ArrayRef[Str]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeWorkspaces');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::WorkSpaces::DescribeWorkspacesResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::WorkSpaces::DescribeWorkspaces - Arguments for method DescribeWorkspaces on Paws::WorkSpaces

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeWorkspaces on the 
Amazon WorkSpaces service. Use the attributes of this class
as arguments to method DescribeWorkspaces.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeWorkspaces.

As an example:

  $service_obj->DescribeWorkspaces(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 BundleId => Str

  

The identifier of a bundle to obtain the WorkSpaces for. All WorkSpaces
that are created from this bundle will be retrieved. This parameter
cannot be combined with any other filter parameter.










=head2 DirectoryId => Str

  

Specifies the directory identifier to which to limit the WorkSpaces.
Optionally, you can specify a specific directory user with the
C<UserName> parameter. This parameter cannot be combined with any other
filter parameter.










=head2 Limit => Int

  

The maximum number of items to return.










=head2 NextToken => Str

  

The C<NextToken> value from a previous call to this operation. Pass
null if this is the first call.










=head2 UserName => Str

  

Used with the C<DirectoryId> parameter to specify the directory user
for which to obtain the WorkSpace.










=head2 WorkspaceIds => ArrayRef[Str]

  

An array of strings that contain the identifiers of the WorkSpaces for
which to retrieve information. This parameter cannot be combined with
any other filter parameter.

Because the CreateWorkspaces operation is asynchronous, the identifier
returned by CreateWorkspaces is not immediately available. If you
immediately call DescribeWorkspaces with this identifier, no
information will be returned.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeWorkspaces in L<Paws::WorkSpaces>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

