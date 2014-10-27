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

# Turn off NOTICES for this demo so the output is cleaner
my $quiet_notices_sth = $dbh->prepare("SET client_min_messages TO warning");
$quiet_notices_sth->execute();

# Create traditional insert statements
my $user_insert_sth = $dbh->prepare('
insert into cte_demo.users (name, email) 
values (?,?) 
returning userid');

my $address_insert_sth = $dbh->prepare('
insert into cte_demo.addresses (userid, address, city, state, zip) 
values (?,?,?,?,?) 
returning addressid');

my $log_insert_sth = $dbh->prepare('
insert into cte_demo.user_history (userid, addressid, action) 
values (?,?,?) 
returning historyid');

# Create new single CTE version
my $cte_insert_sth = $dbh->prepare('
with userdata as (
  insert into cte_demo.users (name, email) values (?,?)
  returning userid
), addressdata as (
  insert into cte_demo.addresses (userid, address, city, state, zip)
  select userid,?,?,?,?
  from userdata
  returning addressid 
), historydata as (
  insert into cte_demo.user_history (userid, addressid, action)
  select userid, addressid, ?
  from userdata, addressdata
  returning historyid
)
select u.userid, a. addressid, h.historyid 
from userdata u, addressdata a, historydata h
');

sub clear_tables {
   my $sth = $dbh->prepare("truncate table cte_demo.user_history cascade");
   $sth->execute();
   $sth = $dbh->prepare("truncate table cte_demo.addresses cascade");
   $sth->execute();
   $sth = $dbh->prepare("truncate table cte_demo.users cascade");
   $sth->execute();
}

my ($name, $email) = ('Chauncy McWinkle', 'therealchauncymcwinkle@google.com');
my ($address, $city, $state, $zip) = ('123 McWinkle Street', 'Columbia', 'MD', '20579');
my ($action) = 'User created';

my ($userid, $addressid, $historyid);

clear_tables();

my $records = 100000;
my $start_time = time;
# Insert records using the traditional method
for(my $i = 0; $i < $records; $i++) {
    $user_insert_sth->execute( $name . $i, $email );
    $user_insert_sth->bind_columns( \$userid );
    $user_insert_sth->fetch();

    $address_insert_sth->execute( $userid, $address, $city, $state, $zip );
    $address_insert_sth->bind_columns( \$addressid );
    $address_insert_sth->fetch();

    $log_insert_sth->execute( $userid, $addressid, $action );
    $log_insert_sth->bind_columns( \$historyid );
    $log_insert_sth->fetch();
}
my $end_time = time;
print "Traditional without transaction took " . ($end_time - $start_time) . " seconds to run.\n";
print "" . ($end_time - $start_time) . " / $records = " . (($end_time - $start_time) / $records)*1000 . "ms per set.\n";
clear_tables();
$start_time = time;
# Insert 100,000 records using the traditional method
for(my $i = 0; $i < $records; $i++) {
    $cte_insert_sth->execute( $name . $i, $email,
                            $address, $city, $state, $zip,
                            $action );
    $cte_insert_sth->bind_columns( \( $userid, $addressid, $historyid ) );
    $cte_insert_sth->fetch();
}
$end_time = time;
print "CTE took " . ($end_time - $start_time) . " seconds to run.\n";
print "" . ($end_time - $start_time) . " / $records = " . (($end_time - $start_time) / $records)*1000 . "ms per set.\n";
clear_tables();
$start_time = time;
# Insert records using the traditional method with transaction
local $dbh->{AutoCommit} = 0;
for(my $i = 0; $i < $records; $i++) {
    $user_insert_sth->execute( $name . $i, $email );
    $user_insert_sth->bind_columns( \$userid );
    $user_insert_sth->fetch();

    $address_insert_sth->execute( $userid, $address, $city, $state, $zip );
    $address_insert_sth->bind_columns( \$addressid );
    $address_insert_sth->fetch();

    $log_insert_sth->execute( $userid, $addressid, $action );
    $log_insert_sth->bind_columns( \$historyid );
    $log_insert_sth->fetch();

    $dbh->commit();
}
my $end_time = time;
local $dbh->{AutoCommit} = 1;
print "Traditional with transaction took " . ($end_time - $start_time) . " seconds to run.\n";
print "" . ($end_time - $start_time) . " / $records = " . (($end_time - $start_time) / $records)*1000 . "ms per set.\n";
