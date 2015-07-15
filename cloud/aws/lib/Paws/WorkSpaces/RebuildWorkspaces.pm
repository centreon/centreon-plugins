
package Paws::WorkSpaces::RebuildWorkspaces {
  use Moose;
  has RebuildWorkspaceRequests => (is => 'ro', isa => 'ArrayRef[Paws::WorkSpaces::RebuildRequest]', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'RebuildWorkspaces');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::WorkSpaces::RebuildWorkspacesResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::WorkSpaces::RebuildWorkspaces - Arguments for method RebuildWorkspaces on Paws::WorkSpaces

=head1 DESCRIPTION

This class represents the parameters used for calling the method RebuildWorkspaces on the 
Amazon WorkSpaces service. Use the attributes of this class
as arguments to method RebuildWorkspaces.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to RebuildWorkspaces.

As an example:

  $service_obj->RebuildWorkspaces(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> RebuildWorkspaceRequests => ArrayRef[Paws::WorkSpaces::RebuildRequest]

  

An array of structures that specify the WorkSpaces to rebuild.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method RebuildWorkspaces in L<Paws::WorkSpaces>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

