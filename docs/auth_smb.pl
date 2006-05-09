#!/usr/local/bin/perl -w
use strict;

use constant PDC => 'saturn'; #warning, not DNS, netbios name - ie saturn instead of saturn.botanics
use constant DOMAIN => 'botanics';

use constant RESTRICTIP => 1;
my @allowedips = qw(127.0.0.1 10.25.25.13);

use constant PORT => 5005; #port to run on

use Authen::Smb;
use IO::Socket::INET;


my $server = IO::Socket::INET->new(LocalPort => PORT,
                                Type      => SOCK_STREAM,
                                Reuse     => 1,
                                Listen    => 1 ) #don't need to queue sockets
    or die "Couldn't be a tcp server on port ".PORT." : $@\n";

while (my ($client, $client_addr) = $server->accept())
{
	#check for valid remote ip
	unless (CheckIp(GetIp($client_addr)))
	{
		print $client "auth 0 IP address (".GetIp($client_addr).") not allowed to use this authenticator\r\n";
		close $client;
		next;
	}

	#get request	
	my $request = <$client>;
	$request =~ s/\r\n/\n/g;
	chomp $request;

	#check for valid request format
	unless ($request =~ /^(auth|pass) (.*){2,3}$/)
	{
		print $client "auth 0 Invalid request format\n";
		close $client;
		next;
	}
	my $type = $1;
	my $message;

	if ($type eq 'auth')
	{
		my ($user, $pass) = $request =~ m/^auth (.*) (.*)$/;
		if  (! $user || ! $pass)
		{
			$message = 'auth 0 Invalid request format';
		}
		else
		{
			my $authResult = Authen::Smb::authen($user, $pass, PDC, '', DOMAIN);
			if ($authResult == 0) #Authen::Smb::NTV_NO_ERROR
			{
				$message = "auth 1 Authenticated $user on ".DOMAIN.' successfully';
			}
			elsif ($authResult == 1) #Authen::Smb::NTV_SERVER_ERROR
			{
				$message = 'auth 0 NTV_SERVER_ERROR';	
			}
			elsif ($authResult == 3) #Authen::Smb::NTV_LOGON_ERROR
			{
				$message = 'auth 0 NTV_LOGON_ERROR';
			}
			elsif ($authResult == 2) # Authen::Smb::NTV_PROTOCOL_ERROR
			{
				$message = 'auth 0 NTV_PROTOCOL_ERROR';
			}
		}
		$user = '';$pass='';
		
	}
	elsif ($type eq 'pass')
	{
		#Authen::Smb doesn't do this yet!
		$message = "pass 0 Authenticator doesn\'t support password changing";
	}	

	$request = '';
	print $client "$message\r\n";
	close $client;
}

#for completeness:
exit;

sub CheckIp
{
	my $ip = shift;
	foreach my $check (@allowedips)
	{
		return 1 if $ip eq $check;
	}
	return 0;
}

sub GetIp
{
	my $client_address = shift;
	my ($port, $packed_ip) = sockaddr_in($client_address);
    return inet_ntoa($packed_ip);
}
