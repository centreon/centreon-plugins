
package Paws::DS::DisableRadius {
  use Moose;
  has DirectoryId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DisableRadius');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DS::DisableRadiusResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DS::DisableRadius - Arguments for method DisableRadius on Paws::DS

=head1 DESCRIPTION

This class represents the parameters used for calling the method DisableRadius on the 
AWS Directory Service service. Use the attributes of this class
as arguments to method DisableRadius.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DisableRadius.

As an example:

  $service_obj->DisableRadius(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> DirectoryId => Str

  

The identifier of the directory to disable MFA for.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DisableRadius in L<Paws::DS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

