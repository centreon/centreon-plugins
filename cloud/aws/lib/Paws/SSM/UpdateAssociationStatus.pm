
package Paws::SSM::UpdateAssociationStatus {
  use Moose;
  has AssociationStatus => (is => 'ro', isa => 'Paws::SSM::AssociationStatus', required => 1);
  has InstanceId => (is => 'ro', isa => 'Str', required => 1);
  has Name => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UpdateAssociationStatus');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::SSM::UpdateAssociationStatusResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SSM::UpdateAssociationStatus - Arguments for method UpdateAssociationStatus on Paws::SSM

=head1 DESCRIPTION

This class represents the parameters used for calling the method UpdateAssociationStatus on the 
Amazon Simple Systems Management Service service. Use the attributes of this class
as arguments to method UpdateAssociationStatus.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UpdateAssociationStatus.

As an example:

  $service_obj->UpdateAssociationStatus(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> AssociationStatus => Paws::SSM::AssociationStatus

  

The association status.










=head2 B<REQUIRED> InstanceId => Str

  

The ID of the instance.










=head2 B<REQUIRED> Name => Str

  

The name of the configuration document.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UpdateAssociationStatus in L<Paws::SSM>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

