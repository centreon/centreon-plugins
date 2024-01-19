package notification::email::templates::resources;
        
use strict;
use warnings;

use notification::email::templates::style qw(get_css);
use notification::email::templates::host qw(get_host_template);
use notification::email::templates::service qw(get_service_template);
use notification::email::templates::bam qw(get_bam_template);
use notification::email::templates::metaservice qw(get_metaservice_template);

our $get_service_template     = get_service_template();
our $get_host_template        = get_host_template();
our $get_bam_template         = get_bam_template();
our $get_metaservice_template = get_metaservice_template();
our $get_css                  = get_css();

1;
