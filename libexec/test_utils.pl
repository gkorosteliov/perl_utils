#!/s/sirsi/Unicorn/Bin/perl -w

$|=1;
use lib "/s/sirsi/Galina/ocls_script/lib";
use Utils;
use strict;


use constant CONFIG_FILE => '/s/sirsi/Galina/config.ini'; #must be changed


#test e-mail
test_email();

exit;
#test get_config_value
test_get_config_value();

#removes spaces and vertical lines
test_cleanup_row();

#returns date/time in the requested format
testDateTime();

#test test_ftp
test_ftp_file();

#set environment
Utils::set_environment();
		


#test if_file_exists
test_if_file_exists();

#test report
test_report();


exit 0;

sub testDateTime
{
	my $now_string = "";
	$now_string = Utils::getDateTime("%Y-%m-%d %H:%M:%S");
	print "Date format %Y-%m-%d %H:%M:%S date=$now_string*\n";
	$now_string = Utils::getDateTime("%m%d%Y");
	print "Date format %m%d%Y date=$now_string*\n";
	$now_string = Utils::getDateTime("%d");
	print "Date format %d date=$now_string*\n";
	$now_string = Utils::getDateTime("%m");
	print "Date format %m date=$now_string*\n";
	$now_string = Utils::getDateTime("%Y");
	print "Date format %Y date=$now_string*\n";
}

sub test_cleanup_row #removes spaces and vertical lines
{
	my $row;
	print "#####################test_cleunup_row#0 - should succed#####################\n";
	print "Cleanup spaces an a verical line at the end\n";
	$row = "  11223344  |  \n";
	print "Row before cleanup is between stars=*$row*\n";
	$row = Utils::cleanup_row($row);
	print "Row after cleanup is between stars=*$row*\n";
	print "###\n";
	
	print "#####################test_cleunup_row#1 - should succed#####################\n";
	print "Cleanup spaces an a verical line at the end\n";
	$row = " 11223344| \n";
	print "Row before cleanup is between stars=*$row*\n";
	$row = Utils::cleanup_row($row);
	print "Row after cleanup is between stars=*$row*\n";
	print "###\n";
}

sub test_ftp_file
{

	my $host = Utils::get_config_value(CONFIG_FILE,"BIBC_HOST");
	my $usr = Utils::get_config_value(CONFIG_FILE,"BIBC_USR");
	my $pwd = Utils::get_config_value(CONFIG_FILE,"BIBC_PWD");
	my $ftp_to_dir = Utils::get_config_value(CONFIG_FILE,"bibc_ftp_to_dir");
	
	print "#####################test_ftp#0 - should succed#####################\n";
	print "Creating a stage file, no errors expected\n";
	system ("echo 1 > remove_me.txt");
	Utils::ftp_file($host, $usr, $pwd, $ftp_to_dir, "remove_me.txt");
	print "###\n";
	
	print "#####################test_ftp#1 - yes error expected#####################\n";
	print "Should complain that file does not exist\n";
	Utils::ftp_file($host, $usr, $pwd, $ftp_to_dir, "galina");
	print "###\n";
	
}

sub test_get_config_value
{
	my $val;
	#stage a config file
	system ("echo 'collection=my_collection' > test.ini");
	
	print "#####################get_config_value#0 - no warning expected#####################\n";
	print "Expect value for parameter \"collection\"\n";
	$val = Utils::get_config_value("test.ini","collection");
	print "Value=".$val."\n";
	print "###\n";
	
	print "#####################get_config_value#1 - no warning expected#####################\n";
	print "Expect warning for non-existing parameter \"galina\"\n";
	$val = Utils::get_config_value("test.ini","galina");
	print "###\n";
	#remove the staged file
	system ("rm test.ini");
		
	print "#####################get_config_value#2 - yes error expected#####################\n";
	print "Please check your e-mail for errors\n";
	Utils::get_config_value("aa","bb");
	print "###\n";
}

sub test_if_file_exists
{
	print "#####################if_file_exists#0 - no warning expected#####################\n";
	Utils::if_file_exists("/s/sirsi/Cron_Code/ftpsummon", "Warning"); #should exist
	print "###\n";
	print "#####################if_file_exists#1 - yes warning expected#####################\n";
	Utils::if_file_exists("aaa.bbb", "Warning"); #should not exist
	print "###\n";
}

sub test_email
{
	
	print "#####################send_mail#0 - should send imail with script name#####################\n";
	my $from = $ENV{'LOGNAME'}.'@localhost';
	my $subject = "The script $0 has failed";
	my $message = "my message";
	Utils::send_mail('gkorosteliov@ocls.ca', $from, $subject, $message);
	print "###\n";
}

sub test_report
{
	my $result; 
	my $report_type;
	my $message;
	
	print "#####################test_report#0 - no warning expected#####################\n";
	$message = "The message";
	$report_type = "Warning";
	$result = system('echo $LOGNAME'); #try to output an environment variable. It should succeed
	Utils::report ($result, $report_type, $message);
	print "###\n";
	
	print "#####################test_report#1 - yes warning expected#####################\n";
	$message = "The message";
	$report_type = "Warning";
	open(IN,'<waw.txt') or Utils::report (1, $report_type, $message); #try to open not existing file, it should fail
	close(IN);
	print "###\n";
	
	print "#####################test_report#2 - no warning expected#####################\n";
	$message = "The message";
	$report_type = "Warning";
	$result = 0;
	Utils::report ($result, $report_type, $message);
	print "###\n";
	
	print "#####################test_report#3 - no error expected#####################\n";
	$message = "The message";
	$report_type = "Error";
	$result = 0;
	Utils::report ($result, $report_type, $message);
	print "###\n";
	
	print "#####################test_report#4 - yes error expected#####################\n";
	$message = "The message";
	$report_type = "Error";
	$result = 1; #failed, must exit
	Utils::report ($result, $report_type, $message);
	print "###\n";
	
	print "#####################\n";
	#if exit failed the script print this message
	print "The last test failed to exit on error\n";
}




