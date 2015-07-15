
package Paws::CloudSearch::DescribeServiceAccessPoliciesResponse {
  use Moose;
  has AccessPolicies => (is => 'ro', isa => 'Paws::CloudSearch::AccessPoliciesStatus', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudSearch::DescribeServiceAccessPoliciesResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> AccessPolicies => Paws::CloudSearch::AccessPoliciesStatus

  

The access rules configured for the domain specified in the request.











=cut

