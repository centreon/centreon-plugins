
package Paws::RDS::ApplyPendingMaintenanceAction {
  use Moose;
  has ApplyAction => (is => 'ro', isa => 'Str', required => 1);
  has OptInType => (is => 'ro', isa => 'Str', required => 1);
  has ResourceIdentifier => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ApplyPendingMaintenanceAction');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RDS::ApplyPendingMaintenanceActionResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ApplyPendingMaintenanceActionResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::ApplyPendingMaintenanceAction - Arguments for method ApplyPendingMaintenanceAction on Paws::RDS

=head1 DESCRIPTION

This class represents the parameters used for calling the method ApplyPendingMaintenanceAction on the 
Amazon Relational Database Service service. Use the attributes of this class
as arguments to method ApplyPendingMaintenanceAction.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ApplyPendingMaintenanceAction.

As an example:

  $service_obj->ApplyPendingMaintenanceAction(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> ApplyAction => Str

  

The pending maintenance action to apply to this resource.










=head2 B<REQUIRED> OptInType => Str

  

A value that specifies the type of opt-in request, or undoes an opt-in
request. An opt-in request of type C<immediate> cannot be undone.

Valid values:

=over

=item * C<immediate> - Apply the maintenance action immediately.

=item * C<next-maintenance> - Apply the maintenance action during the
next maintenance window for the resource.

=item * C<undo-opt-in> - Cancel any existing C<next-maintenance> opt-in
requests.

=back










=head2 B<REQUIRED> ResourceIdentifier => Str

  

The ARN of the resource that the pending maintenance action applies to.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ApplyPendingMaintenanceAction in L<Paws::RDS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

