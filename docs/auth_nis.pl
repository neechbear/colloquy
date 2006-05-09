#!/usr/local/bin/perl -w
use strict;

use constant PORT => 5005;

use constant RESTRICTIP => 1;
my @allowedips = qw(127.0.0.1 10.25.25.13);

use Net::NIS;
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
			my $result = Authenticate($user, $pass);
			if ($result)
			{
				$message = 'auth 0 $message';
			}
			else
			{
				$message = 'auth 1 Authenticated successfully';
			}
		}
		$user = '';$pass='';
		
	}
	elsif ($type eq 'pass')
	{
		#Decided not support this
		$message = "pass 0 Authenticator doesn\'t support password changing";
	}	

	$request = '';
	print $client "$message\r\n";
	close $client;
}

#for completeness:
exit;

sub Authenticate
{
	my ($name, $pass) = @_;

	#get NIS domain
	my $domain = Net::NIS::yp_get_default_domain();
	return "Cannot obtain NIS domain" unless $domain;

	#get the users entry
	my ($status, $entry) = Net::NIS::yp_match($domain, "passwd.byname", $name);	
	if ($status)
	{
		return "Could not find username in NIS domain $domain";
	}

	my ($user, $hash, $uid, $gid, $gecos, $dir, $shell) = split(/:/, $entry);
	if(crypt($pass, $hash) eq $hash)
	{
		#Authenticate OK
		return 0;
	}
	return "Failed to Authenticate $name in NIS domain $domain";
}

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
