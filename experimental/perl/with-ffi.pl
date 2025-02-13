#!/usr/bin/perl

use strict;
use warnings;
use lib '/home/david/perl5/lib/perl5';
use FFI::Platypus 2.00;
my $ffi = FFI::Platypus->new(api => 2, lang => => 'Rust');

$ffi->lib(
    '../target/debug/libconn.so');

### Types ###
$ffi->type('object(SnmpResult)' => 'snmpresult_t');
$ffi->type('object(SnmpVariable)' => 'snmpvariable_t');

### Global functions ###
$ffi->attach(snmp_get => ['string', 'string', 'string'] => 'snmpresult_t');
$ffi->attach(snmp_walk => ['string', 'string'] => 'snmpresult_t');

$ffi->attach(snmpresult_variables_count => ['snmpresult_t'] => 'usize');
$ffi->attach(snmpresult_get_variable => ['snmpresult_t', 'usize'] => 'snmpvariable_t');
$ffi->attach( snmpresult_DESTROY      => [ 'snmpresult_t' ] );

$ffi->attach(snmpvariable_get_name => ['snmpvariable_t'] => 'string');
$ffi->attach(snmpvariable_get_value => ['snmpvariable_t'] => 'string');
$ffi->attach( snmpvariable_DESTROY      => [ 'snmpvariable_t' ] );

### Main program ###

my $result = snmp_walk('127.0.0.1:161', '1.3.6.1.2.1.25.3.3.1.2');
for (my $i = 0; $i < snmpresult_variables_count($result); $i++) {
    my $variable = snmpresult_get_variable($result, $i);
    print snmpvariable_get_name($variable) . " => " . snmpvariable_get_value($variable) . "\n";
}
