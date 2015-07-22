package Paws::Route53Domains {
  use Moose;
  sub service { 'route53domains' }
  sub version { '2014-05-15' }
  sub target_prefix { 'Route53Domains_v20140515' }
  sub json_version { "1.1" }

  with 'Paws::API::Caller', 'Paws::API::EndpointResolver', 'Paws::Net::V4Signature', 'Paws::Net::JsonCaller', 'Paws::Net::JsonResponse';

  
  sub CheckDomainAvailability {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53Domains::CheckDomainAvailability', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteTagsForDomain {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53Domains::DeleteTagsForDomain', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DisableDomainAutoRenew {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53Domains::DisableDomainAutoRenew', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DisableDomainTransferLock {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53Domains::DisableDomainTransferLock', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub EnableDomainAutoRenew {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53Domains::EnableDomainAutoRenew', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub EnableDomainTransferLock {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53Domains::EnableDomainTransferLock', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetDomainDetail {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53Domains::GetDomainDetail', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetOperationDetail {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53Domains::GetOperationDetail', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListDomains {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53Domains::ListDomains', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListOperations {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53Domains::ListOperations', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListTagsForDomain {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53Domains::ListTagsForDomain', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RegisterDomain {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53Domains::RegisterDomain', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RetrieveDomainAuthCode {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53Domains::RetrieveDomainAuthCode', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub TransferDomain {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53Domains::TransferDomain', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateDomainContact {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53Domains::UpdateDomainContact', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateDomainContactPrivacy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53Domains::UpdateDomainContactPrivacy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateDomainNameservers {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53Domains::UpdateDomainNameservers', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateTagsForDomain {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Route53Domains::UpdateTagsForDomain', @_);
    return $self->caller->do_call($self, $call_object);
  }
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Route53Domains - Perl Interface to AWS Amazon Route 53 Domains

=head1 SYNOPSIS

  use Paws;

  my $obj = Paws->service('Route53Domains')->new;
  my $res = $obj->Method(
    Arg1 => $val1,
    Arg2 => [ 'V1', 'V2' ],
    # if Arg3 is an object, the HashRef will be used as arguments to the constructor
    # of the arguments type
    Arg3 => { Att1 => 'Val1' },
    # if Arg4 is an array of objects, the HashRefs will be passed as arguments to
    # the constructor of the arguments type
    Arg4 => [ { Att1 => 'Val1'  }, { Att1 => 'Val2' } ],
  );

=head1 DESCRIPTION



Amazon Route 53 Domains

Amazon Route 53 permits Interned Domain Name registration, trasnfer and
management










=head1 METHODS

=head2 CheckDomainAvailability(DomainName => Str, [IdnLangCode => Str])

Each argument is described in detail in: L<Paws::Route53Domains::CheckDomainAvailability>

Returns: a L<Paws::Route53Domains::CheckDomainAvailabilityResponse> instance

  

This operation checks the availability of one domain name. You can
access this API without authenticating. Note that if the availability
status of a domain is pending, you must submit another request to
determine the availability of the domain name.











=head2 DeleteTagsForDomain(DomainName => Str, TagsToDelete => ArrayRef[Str])

Each argument is described in detail in: L<Paws::Route53Domains::DeleteTagsForDomain>

Returns: a L<Paws::Route53Domains::DeleteTagsForDomainResponse> instance

  

This operation deletes the specified tags for a domain.

All tag operations are eventually consistent; subsequent operations may
not immediately represent all issued operations.











=head2 DisableDomainAutoRenew(DomainName => Str)

Each argument is described in detail in: L<Paws::Route53Domains::DisableDomainAutoRenew>

Returns: a L<Paws::Route53Domains::DisableDomainAutoRenewResponse> instance

  

This operation disables automatic renewal of domain registration for
the specified domain.

Caution! Amazon Route 53 doesn't have a manual renewal process, so if
you disable automatic renewal, registration for the domain will not be
renewed when the expiration date passes, and you will lose control of
the domain name.











=head2 DisableDomainTransferLock(DomainName => Str)

Each argument is described in detail in: L<Paws::Route53Domains::DisableDomainTransferLock>

Returns: a L<Paws::Route53Domains::DisableDomainTransferLockResponse> instance

  

This operation removes the transfer lock on the domain (specifically
the C<clientTransferProhibited> status) to allow domain transfers. We
recommend you refrain from performing this action unless you intend to
transfer the domain to a different registrar. Successful submission
returns an operation ID that you can use to track the progress and
completion of the action. If the request is not completed successfully,
the domain registrant will be notified by email.











=head2 EnableDomainAutoRenew(DomainName => Str)

Each argument is described in detail in: L<Paws::Route53Domains::EnableDomainAutoRenew>

Returns: a L<Paws::Route53Domains::EnableDomainAutoRenewResponse> instance

  

This operation configures Amazon Route 53 to automatically renew the
specified domain before the domain registration expires. The cost of
renewing your domain registration is billed to your AWS account.

The period during which you can renew a domain name varies by TLD. For
a list of TLDs and their renewal policies, see "Renewal, restoration,
and deletion times" on the website for our registrar partner, Gandi.
Route 53 requires that you renew before the end of the renewal period
that is listed on the Gandi website so we can complete processing
before the deadline.











=head2 EnableDomainTransferLock(DomainName => Str)

Each argument is described in detail in: L<Paws::Route53Domains::EnableDomainTransferLock>

Returns: a L<Paws::Route53Domains::EnableDomainTransferLockResponse> instance

  

This operation sets the transfer lock on the domain (specifically the
C<clientTransferProhibited> status) to prevent domain transfers.
Successful submission returns an operation ID that you can use to track
the progress and completion of the action. If the request is not
completed successfully, the domain registrant will be notified by
email.











=head2 GetDomainDetail(DomainName => Str)

Each argument is described in detail in: L<Paws::Route53Domains::GetDomainDetail>

Returns: a L<Paws::Route53Domains::GetDomainDetailResponse> instance

  

This operation returns detailed information about the domain. The
domain's contact information is also returned as part of the output.











=head2 GetOperationDetail(OperationId => Str)

Each argument is described in detail in: L<Paws::Route53Domains::GetOperationDetail>

Returns: a L<Paws::Route53Domains::GetOperationDetailResponse> instance

  

This operation returns the current status of an operation that is not
completed.











=head2 ListDomains([Marker => Str, MaxItems => Int])

Each argument is described in detail in: L<Paws::Route53Domains::ListDomains>

Returns: a L<Paws::Route53Domains::ListDomainsResponse> instance

  

This operation returns all the domain names registered with Amazon
Route 53 for the current AWS account.











=head2 ListOperations([Marker => Str, MaxItems => Int])

Each argument is described in detail in: L<Paws::Route53Domains::ListOperations>

Returns: a L<Paws::Route53Domains::ListOperationsResponse> instance

  

This operation returns the operation IDs of operations that are not yet
complete.











=head2 ListTagsForDomain(DomainName => Str)

Each argument is described in detail in: L<Paws::Route53Domains::ListTagsForDomain>

Returns: a L<Paws::Route53Domains::ListTagsForDomainResponse> instance

  

This operation returns all of the tags that are associated with the
specified domain.

All tag operations are eventually consistent; subsequent operations may
not immediately represent all issued operations.











=head2 RegisterDomain(AdminContact => Paws::Route53Domains::ContactDetail, DomainName => Str, DurationInYears => Int, RegistrantContact => Paws::Route53Domains::ContactDetail, TechContact => Paws::Route53Domains::ContactDetail, [AutoRenew => Bool, IdnLangCode => Str, PrivacyProtectAdminContact => Bool, PrivacyProtectRegistrantContact => Bool, PrivacyProtectTechContact => Bool])

Each argument is described in detail in: L<Paws::Route53Domains::RegisterDomain>

Returns: a L<Paws::Route53Domains::RegisterDomainResponse> instance

  

This operation registers a domain. Domains are registered by the AWS
registrar partner, Gandi. For some top-level domains (TLDs), this
operation requires extra parameters.

When you register a domain, Amazon Route 53 does the following:

=over

=item * Creates a Amazon Route 53 hosted zone that has the same name as
the domain. Amazon Route 53 assigns four name servers to your hosted
zone and automatically updates your domain registration with the names
of these name servers.

=item * Enables autorenew, so your domain registration will renew
automatically each year. We'll notify you in advance of the renewal
date so you can choose whether to renew the registration.

=item * Optionally enables privacy protection, so WHOIS queries return
contact information for our registrar partner, Gandi, instead of the
information you entered for registrant, admin, and tech contacts.

=item * If registration is successful, returns an operation ID that you
can use to track the progress and completion of the action. If the
request is not completed successfully, the domain registrant is
notified by email.

=item * Charges your AWS account an amount based on the top-level
domain. For more information, see Amazon Route 53 Pricing.

=back











=head2 RetrieveDomainAuthCode(DomainName => Str)

Each argument is described in detail in: L<Paws::Route53Domains::RetrieveDomainAuthCode>

Returns: a L<Paws::Route53Domains::RetrieveDomainAuthCodeResponse> instance

  

This operation returns the AuthCode for the domain. To transfer a
domain to another registrar, you provide this value to the new
registrar.











=head2 TransferDomain(AdminContact => Paws::Route53Domains::ContactDetail, DomainName => Str, DurationInYears => Int, RegistrantContact => Paws::Route53Domains::ContactDetail, TechContact => Paws::Route53Domains::ContactDetail, [AuthCode => Str, AutoRenew => Bool, IdnLangCode => Str, Nameservers => ArrayRef[Paws::Route53Domains::Nameserver], PrivacyProtectAdminContact => Bool, PrivacyProtectRegistrantContact => Bool, PrivacyProtectTechContact => Bool])

Each argument is described in detail in: L<Paws::Route53Domains::TransferDomain>

Returns: a L<Paws::Route53Domains::TransferDomainResponse> instance

  

This operation transfers a domain from another registrar to Amazon
Route 53. When the transfer is complete, the domain is registered with
the AWS registrar partner, Gandi.

For transfer requirements, a detailed procedure, and information about
viewing the status of a domain transfer, see Transferring Registration
for a Domain to Amazon Route 53 in the Amazon Route 53 Developer Guide.

If the registrar for your domain is also the DNS service provider for
the domain, we highly recommend that you consider transferring your DNS
service to Amazon Route 53 or to another DNS service provider before
you transfer your registration. Some registrars provide free DNS
service when you purchase a domain registration. When you transfer the
registration, the previous registrar will not renew your domain
registration and could end your DNS service at any time.

Caution! If the registrar for your domain is also the DNS service
provider for the domain and you don't transfer DNS service to another
provider, your website, email, and the web applications associated with
the domain might become unavailable.

If the transfer is successful, this method returns an operation ID that
you can use to track the progress and completion of the action. If the
transfer doesn't complete successfully, the domain registrant will be
notified by email.











=head2 UpdateDomainContact(DomainName => Str, [AdminContact => Paws::Route53Domains::ContactDetail, RegistrantContact => Paws::Route53Domains::ContactDetail, TechContact => Paws::Route53Domains::ContactDetail])

Each argument is described in detail in: L<Paws::Route53Domains::UpdateDomainContact>

Returns: a L<Paws::Route53Domains::UpdateDomainContactResponse> instance

  

This operation updates the contact information for a particular domain.
Information for at least one contact (registrant, administrator, or
technical) must be supplied for update.

If the update is successful, this method returns an operation ID that
you can use to track the progress and completion of the action. If the
request is not completed successfully, the domain registrant will be
notified by email.











=head2 UpdateDomainContactPrivacy(DomainName => Str, [AdminPrivacy => Bool, RegistrantPrivacy => Bool, TechPrivacy => Bool])

Each argument is described in detail in: L<Paws::Route53Domains::UpdateDomainContactPrivacy>

Returns: a L<Paws::Route53Domains::UpdateDomainContactPrivacyResponse> instance

  

This operation updates the specified domain contact's privacy setting.
When the privacy option is enabled, personal information such as postal
or email address is hidden from the results of a public WHOIS query.
The privacy services are provided by the AWS registrar, Gandi. For more
information, see the Gandi privacy features.

This operation only affects the privacy of the specified contact type
(registrant, administrator, or tech). Successful acceptance returns an
operation ID that you can use with GetOperationDetail to track the
progress and completion of the action. If the request is not completed
successfully, the domain registrant will be notified by email.











=head2 UpdateDomainNameservers(DomainName => Str, Nameservers => ArrayRef[Paws::Route53Domains::Nameserver], [FIAuthKey => Str])

Each argument is described in detail in: L<Paws::Route53Domains::UpdateDomainNameservers>

Returns: a L<Paws::Route53Domains::UpdateDomainNameserversResponse> instance

  

This operation replaces the current set of name servers for the domain
with the specified set of name servers. If you use Amazon Route 53 as
your DNS service, specify the four name servers in the delegation set
for the hosted zone for the domain.

If successful, this operation returns an operation ID that you can use
to track the progress and completion of the action. If the request is
not completed successfully, the domain registrant will be notified by
email.











=head2 UpdateTagsForDomain(DomainName => Str, [TagsToUpdate => ArrayRef[Paws::Route53Domains::Tag]])

Each argument is described in detail in: L<Paws::Route53Domains::UpdateTagsForDomain>

Returns: a L<Paws::Route53Domains::UpdateTagsForDomainResponse> instance

  

This operation adds or updates tags for a specified domain.

All tag operations are eventually consistent; subsequent operations may
not immediately represent all issued operations.











=head1 SEE ALSO

This service class forms part of L<Paws>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

