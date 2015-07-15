
package Paws::Route53::GetHostedZoneResponse {
  use Moose;
  has DelegationSet => (is => 'ro', isa => 'Paws::Route53::DelegationSet');
  has HostedZone => (is => 'ro', isa => 'Paws::Route53::HostedZone', required => 1);
  has VPCs => (is => 'ro', isa => 'ArrayRef[Paws::Route53::VPC]', traits => ['Unwrapped'], xmlname => 'VPC');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Route53:: - Arguments for method  on Paws::Route53

=head1 DESCRIPTION

This class represents the parameters used for calling the method  on the 
Amazon Route 53 service. Use the attributes of this class
as arguments to method .

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to .

As an example:

  $service_obj->(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 DelegationSet => Paws::Route53::DelegationSet

  

A complex type that contains information about the name servers for the
specified hosted zone.










=head2 B<REQUIRED> HostedZone => Paws::Route53::HostedZone

  

A complex type that contains the information about the specified hosted
zone.










=head2 VPCs => ArrayRef[Paws::Route53::VPC]

  

A complex type that contains information about VPCs associated with the
specified hosted zone.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method  in L<Paws::Route53>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

