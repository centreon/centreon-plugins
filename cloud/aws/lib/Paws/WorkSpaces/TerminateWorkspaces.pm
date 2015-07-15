
package Paws::WorkSpaces::TerminateWorkspaces {
  use Moose;
  has TerminateWorkspaceRequests => (is => 'ro', isa => 'ArrayRef[Paws::WorkSpaces::TerminateRequest]', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'TerminateWorkspaces');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::WorkSpaces::TerminateWorkspacesResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::WorkSpaces::TerminateWorkspaces - Arguments for method TerminateWorkspaces on Paws::WorkSpaces

=head1 DESCRIPTION

This class represents the parameters used for calling the method TerminateWorkspaces on the 
Amazon WorkSpaces service. Use the attributes of this class
as arguments to method TerminateWorkspaces.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to TerminateWorkspaces.

As an example:

  $service_obj->TerminateWorkspaces(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> TerminateWorkspaceRequests => ArrayRef[Paws::WorkSpaces::TerminateRequest]

  

An array of structures that specify the WorkSpaces to terminate.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method TerminateWorkspaces in L<Paws::WorkSpaces>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

