
package Paws::OpsWorks::SetLoadBasedAutoScaling {
  use Moose;
  has DownScaling => (is => 'ro', isa => 'Paws::OpsWorks::AutoScalingThresholds');
  has Enable => (is => 'ro', isa => 'Bool');
  has LayerId => (is => 'ro', isa => 'Str', required => 1);
  has UpScaling => (is => 'ro', isa => 'Paws::OpsWorks::AutoScalingThresholds');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'SetLoadBasedAutoScaling');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::SetLoadBasedAutoScaling - Arguments for method SetLoadBasedAutoScaling on Paws::OpsWorks

=head1 DESCRIPTION

This class represents the parameters used for calling the method SetLoadBasedAutoScaling on the 
AWS OpsWorks service. Use the attributes of this class
as arguments to method SetLoadBasedAutoScaling.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to SetLoadBasedAutoScaling.

As an example:

  $service_obj->SetLoadBasedAutoScaling(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 DownScaling => Paws::OpsWorks::AutoScalingThresholds

  

An C<AutoScalingThresholds> object with the downscaling threshold
configuration. If the load falls below these thresholds for a specified
amount of time, AWS OpsWorks stops a specified number of instances.










=head2 Enable => Bool

  

Enables load-based auto scaling for the layer.










=head2 B<REQUIRED> LayerId => Str

  

The layer ID.










=head2 UpScaling => Paws::OpsWorks::AutoScalingThresholds

  

An C<AutoScalingThresholds> object with the upscaling threshold
configuration. If the load exceeds these thresholds for a specified
amount of time, AWS OpsWorks starts a specified number of instances.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method SetLoadBasedAutoScaling in L<Paws::OpsWorks>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

