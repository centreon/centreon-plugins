
package Paws::DeviceFarm::CreateProject {
  use Moose;
  has name => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateProject');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DeviceFarm::CreateProjectResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DeviceFarm::CreateProject - Arguments for method CreateProject on Paws::DeviceFarm

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateProject on the 
AWS Device Farm service. Use the attributes of this class
as arguments to method CreateProject.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateProject.

As an example:

  $service_obj->CreateProject(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> name => Str

  

The project's name.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateProject in L<Paws::DeviceFarm>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

