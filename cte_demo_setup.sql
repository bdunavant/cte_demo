#! /opt/OMNIperl/bin/perl

use strict;
use DBI;
use DBD::Pg;

my $dbname = '';
my $host = '';
my $username = '';
my $password = '';

if( !$dbname || !$host || !$username || !$password ) {
    print "Please add your database credentials to the script.\n";
    exit;
}

my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$host", $username, $password);

my @setup_lines = ( 
"drop schema if exists cte_demo cascade",
"create schema cte_demo",

"create table cte_demo.users (
  userid serial not null primary key,
  name text,
  email text
)",

"create table cte_demo.addresses (
  addressid serial not null primary key,
  userid integer,
  address text,
  city text,
  state text,
  zip text
)",

"create table cte_demo.user_history (
  historyid serial not null primary key,
  userid integer not null REFERENCES cte_demo.users(userid),
  addressid integer not null REFERENCES cte_demo.addresses(addressid),
  action text
)"
);

foreach( @setup_lines ) {
    $dbh->do( $_ );
}
