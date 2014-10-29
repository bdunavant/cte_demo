Scripts/code for displaying speed differences between using a CTE
vs the same queries in a transaction.

To recreate, setup an RDS instance of Postgres and take note of the credentials (and make sure your security group lets your instances talk to the database).

Create an instance using the OmniOS r151012 AMI and run the following:

    pkg set-publisher -g http://pkg.omniti.com/omniti-ms/ ms.omniti.com
    pkg set-publisher -g http://pkg.omniti.com/omniti-perl/ perl.omniti.com
    pkg install omniti/perl/dbd-pg
    pkg install developer/versioning/git
    git clone https://github.com/bdunavant/cte_demo.git
    <update code with database credentials>
    ./cte_demo/cte_demo_setup.pl
    ./cte_demo/cte_code.pl

