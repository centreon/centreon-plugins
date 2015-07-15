
package Paws::IAM::UpdateGroup {
  use Moose;
  has GroupName => (is => 'ro', isa => 'Str', required => 1);
  has NewGroupName => (is => 'ro', isa => 'Str');
  has NewPath => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UpdateGroup');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::UpdateGroup - Arguments for method UpdateGroup on Paws::IAM

=head1 DESCRIPTION

This class represents the parameters used for calling the method UpdateGroup on the 
AWS Identity and Access Management service. Use the attributes of this class
as arguments to method UpdateGroup.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UpdateGroup.

As an example:

  $service_obj->UpdateGroup(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> GroupName => Str

  

Name of the group to update. If you're changing the name of the group,
this is the original name.










=head2 NewGroupName => Str

  

New name for the group. Only include this if changing the group's name.










=head2 NewPath => Str

  

New path for the group. Only include this if changing the group's path.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UpdateGroup in L<Paws::IAM>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

