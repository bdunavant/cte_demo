#! /opt/OMNIperl/bin/perl
# /opt/local/bin/perl

use strict;
use DBI;
use DBD::Pg;

my $dbname = '';
my $host = '';
my $username = '';
my $password = '';

if( !$dbname || !$host || !$username || !$password) {
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

sub clear_tables {
   my $sth = $dbh->prepare("truncate table cte_demo.users cascade");
   $sth->execute();
}

my ($name, $email) = ('Chauncy McWinkle', 'therealchauncymcwinkle@google.com');
my ($userid, $addressid, $historyid, $start_time, $end_time);

my $sets = 100000;
my $records = 2;

while($records <= 10) {
    clear_tables();
    $start_time = time;
    # Insert records using the traditional method
    for(my $i = 0; $i < $sets; $i++) {
        for(my $j = 0; $j < $records; $j++) {
            $user_insert_sth->execute( "$name $i $j", $email );
            $user_insert_sth->bind_columns( \$userid );
            $user_insert_sth->fetch();
        }
    }
    $end_time = time;
    print "N : $records, ".($end_time - $start_time).", ".(($end_time - $start_time) / $sets)*1000 . "\n";

    clear_tables();
    $start_time = time;
    # Insert records using the traditional method with transaction
    local $dbh->{AutoCommit} = 0;
    for(my $i = 0; $i < $sets; $i++) {
        for(my $j = 0; $j < $records; $j++) {
            $user_insert_sth->execute( "$name $i $j", $email );
            $user_insert_sth->bind_columns( \$userid );
            $user_insert_sth->fetch();
        }
        $dbh->commit();
    }
    my $end_time = time;
    local $dbh->{AutoCommit} = 1;
    print "Y : $records, ".($end_time - $start_time).", ".(($end_time - $start_time) / $sets)*1000 . "\n";

    clear_tables();

    # Create my CTE query for this number of records
    my $query = "WITH ";
    for(my $i = 1; $i <= $records; $i++) {
        $query .= "userdata$i as (
                      insert into cte_demo.users (name, email) values (?,?)
                       returning userid
                  )";
        $query .= ", " if $i != $records;
    }
    $query .= " select " . (join ', ', map { "userdata$_.userid" } (1..$records)) .
              " from " . (join ', ', map { "userdata$_" } (1..$records));

    my $cte_insert_sth = $dbh->prepare($query);
    $start_time = time;
    # Insert 100,000 records using the traditional method
    for(my $i = 0; $i < $sets; $i++) {
        $cte_insert_sth->execute( map { ("$name $i $_", $email ) } (1..$records) );
        $cte_insert_sth->bind_columns( (map { \$userid; } (1..$records)) );
        $cte_insert_sth->fetch();
    }
    $end_time = time;
    print "C : $records, ".($end_time - $start_time).", ".(($end_time - $start_time) / $sets)*1000 . "\n";

    $records++;
}
