#!/s/sirsi/Unicorn/Bin/perl -w

package Utils;

use POSIX qw(strftime);
use strict;
use Net::FTP;

$|=1;
#use constant SEND_TO => 'rt@ocls.ca';
use constant CONFIG_FILE => '/s/sirsi/Galina/config.ini'; #must be changed

sub getDateTime
{
	my ($format) = @_;
	my $now_string = strftime $format, localtime;
	return $now_string;
}


#used to ftp a file
sub ftp_file
{
	my ($host, $usr, $pwd, $ftp_to_dir, $ftp_file_ful_path) = @_;
	if(-s $ftp_file_ful_path){
	  my $session = Net::FTP -> new($host, Debug => 0)
				 or report (1, "Error", "ftp_file Could not open the session to $host");
	  $session -> login($usr, $pwd)
				  or report (1, "Error", "ftp_file Could not login ".$session->message);
	  $session -> cwd($ftp_to_dir)
				  or report (1, "Error", "ftp_file Could not change to bibdir ".$session->message);
	  $session -> ascii
				  or report (1, "Error", "ftp_file Could not change to ascii ".$session->message);
	  $session -> put($ftp_file_ful_path)
				  or report (1, "Error", "ftp_file Failed to put $ftp_file_ful_path ".$session -> message);
	  $session -> quit;
	  #logging to /s/sirsi/.local/share/lftp/transfer_log
	  my $datetime = getDateTime("%Y-%m-%d %H:%M:%S");
	  my $cmd = "echo \"".$datetime." ".$ftp_file_ful_path." -> ".$host.":/".$ftp_to_dir."\" >> /s/sirsi/.local/share/lftp/transfer_log";
	  my $res = system ($cmd);
	  report ($res, "Warning", "Unable to execute the command $cmd" );
	}
	else
	{
		report (1, "Error", "ftp_file The file $ftp_file_ful_path does not exist");
	}

}

#this function is used to report errors and warnings with commands like system and open file 
#the report function checks the $result (0-good 1to256 not good) and returns "true=1" if no problems
#it prints warning message and returns success in case of "Warning" report_type
#it prints warning message and exits in case of "Error" report_type
sub report 
{
	my ($result, $report_type, $message) = @_;
	
	if($result == 0)
	{
		#success 
		return 1;
	}
	if ((!defined $message) ||($message eq ""))
	{
		$message = "No message provided";
	}
	print "$report_type: $message\n";
	
	#report if Error or (if Warning and it tells to report in config file)
	my $output_warning = get_config_value(CONFIG_FILE,"output_warning");
	if (($report_type eq "Error") || (($report_type eq "Warning") && ($output_warning eq "yes")))
	{
		my $from = $ENV{'LOGNAME'}.'@localhost';
		my $subject = "The script $0 has failed";

		my $send_to = get_config_value(CONFIG_FILE,"send_to");
		send_mail($send_to, $from, $subject, $message);
	}
	
	if($report_type eq "Warning")
	{
		#success 
		return 1;
	}
	
	exit 1;

}

sub get_config_value
{
	my ($cfg_file, $name)=@_;
	my %configParamHash = ();
	my $_configParam;
	my $_paramValue;
	if (! open ( _FH, $cfg_file ) )
	{
		report (1, "Error", "Unable to read from configuration file $cfg_file");
	}
	 
	while ( <_FH> ) {
		chomp;
		s/#.*//;                # ignore comments
		s/^\s+//;               # trim leading spaces if any
		s/\s+$//;               # trim leading spaces if any
		s/^\[.*//;				# ignore section names
		next unless length;
		($_configParam, $_paramValue) = split(/\s*=\s*/, $_, 2);
		$configParamHash{$_configParam} = $_paramValue;
	}
	close _FH;
	if (exists $configParamHash{$name})
	{
		return $configParamHash{$name};
	}
	report (1, "Warning", "Unable to find parameter \"$name\" in configuration file $cfg_file");
	return "";
}

sub set_environment
{

	$ENV{'PATH'} = ':/s/sirsi/Unicorn/Bincustom:/s/sirsi/Unicorn/Bin:/s/sirsi/Unicorn/Search/Bin:/s/oracle/11g/bin:/s/sirsi/jdk1.6.0_31/bin:/bin:/usr/bin:/etc:/usr/sbin:/usr/ccs/bin:/usr/ucb:/usr/sbin:/sbin';
	$ENV{'LD_LIBRARY_PATH'} = ':/s/sirsi/Unicorn/Oracle_client/10.2.0.3:/usr/local/sirsi/lib64';
	$ENV{'UPATH'} = '/s/sirsi/Unicorn/Config/upath';
	$ENV{'BRSConfig'} = '/s/sirsi/Unicorn/Config/brspath';
	$ENV{'ORACLE_BASE'} = '/s/oracle';
	$ENV{'ORACLE_HOME'} = '/s/oracle/11g';
	$ENV{'ORACLE_SID'} = 'sher';
	$ENV{'TNS_ADMIN'} = '/s/sirsi/Unicorn/Config';
	
	#my $res = system ("env");
	#report ($res, "Error", "Reporting environment failed.");

}

sub send_mail
{
	#my $to = 'gkorosteliov@ocls.ca'; #SEND_TO
	#my $from = $ENV{'LOGNAME'}.'@localhost';
	#my $subject = 'Test Email';
	#my $message = 'This is test email sent by Perl Script';
	my($to, $from, $subject, $message) = @_;
	 
	open(MAIL, "|/usr/sbin/sendmail -t");
	 
	print MAIL "To: $to\n";
	print MAIL "From: $from\n";
	print MAIL "Subject: $subject\n\n";
	print MAIL "Content-type: text/html\n";
	print MAIL $message;
	close(MAIL);
	
	
	print "Email Sent Successfully\n";
}

sub if_file_exists
{
	my($check_file, $report_type) = @_;
	if (!-e $check_file)
	{
		report (1, $report_type, "The $check_file does not exist");#to report an error #result should be more tnan 0
		return 0;
	} 
	return 1;
}

sub cleanup_row #removes spaces and vertical lines
{
	my($row) = @_;
	chomp $row;
	$row =~ s/^\s+//;
	$row =~ s/\s*$//;
	$row =~ s/\|$//;#remove vertical lines
	$row =~ s/\s*$//;#remove space that was before the vertical line
	return $row;
}

1;
