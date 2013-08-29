#!/usr/bin/perl -w
use strict;
use warnings;
use Data::Dumper;

my $tweeting_enabled=1;

warn "tweeting disabled" unless $tweeting_enabled;

#http://www.windley.com/archives/2009/01/a_retweeter_in_perl.shtml

my @quotes= ( "At least we haven't had an earthquake lately.", 
		"That's just what would happen", 
		"Somebody must have taken it... How Like Them", 
		"Good morning... If it is a good morning... Which I doubt", 
		"We can't all, and some of us don't. That's all there is to it.", 
		" End of the road... nothing to do... and no hope of things getting better. Sounds like Saturday night at my house.",
		"It worked. Didn't expect it to, but I'm kinda - glad", 
		"The sky has finally fallen. Always knew it would.",
		"I don't seem to have felt how at all for a long time",
		"Even if you think you have nothing worth stealing, someone will come along and take your tail. How like them",
		"You can give an eeyore a happy ending, but the miserable beginning remains forever",
		"Life is a box of thistles, and I've been dealt all the really tough and prickly ones",
		"Well, anyhow, it didn't rain",
		"Go and enjoy yourself... I'll stay here and be miserable, with no presents, no cake, no candles.",
		"This tweeting business. Blackberrys and what-not. Over-rated, if you ask me. Silly stuff. Nothing in it.",
		"They're funny things, Accidents. You never have them till you're having them.",
		"One can't complain. I have my friends. Someone tweeted to me only yesterday.",
		"It just shows what can be done by taking a little trouble",
		"I don't hold with all the tweeting. This modern telephone nonsense.",
		"We can't all, and some of us don't. That's all there is to it.",
		"When trying to rescue friends from a tree, make sure the plan doesn't involve having everybody stand on your back.",
		"A little Consideration, a little thought for others, makes all the difference. Or so they say.",
		"When someone says 'How-do-you-do,' just say that you didn't.",
		"Always watch where you are going. Otherwise, you may step on a piece of forest that was left out by mistake",
		"A Proper Tea is much nicer than a Very Nearly Tea, which is one you forget about afterwards",
		"I thought I did. But I suppose I don't. After all, we can't all have houses",
		"No matter how bad things seem, nothing could be worse than being used as a towel rail",
		"Merriment and What-not. Don't apologise, it's just what would happen",
		"Weeds are flowers too, once you get to know them."
		);

my @to_eeyore= ("Good morning... XXX ... If it is a good morning... Which I doubt", 
		"It just shows what can be done by taking a little trouble, Do you see, XXX? Brains first and then Hard Work.",
		"Hallo XXX. Thank you for asking, but I shall go out again in a day or two.", 
		"XXX It isn't mine. Then again, few things are", 
		"XXX Kind and thoughtful; don't mention it.",
		"Unexpected and gratifying, thank you XXX. If a little lacking in smack",
		"XXX I'm feeling particularly cheerful this morning",
		"XXX At least we haven't had an earthquake lately."
		);

use Net::Twitter::Lite::WithAPIv1_1;
use DateTime;
use Fcntl;
use SDBM_File;
use Scalar::Util 'blessed';
use File::Copy;
#die;

my $dt = DateTime->now;
$dt->subtract( minutes => 60); 

#my $class = 'DateTime::Format::HTTP';
#my $since = $class->format_datetime($dt);
my %seen_this_time;
my @localtime= localtime;
my $year= $localtime[5]+1900;

chdir ("$ENV{HOME}/work/eeyore-twitter/");
my $today_string = $dt->strftime("%M");
my $seen_dir = "./seen";
my $seen_file = "$seen_dir/latest.db";
my $backup_file = "$seen_dir/$today_string.db";

# make a backup of the hash and open it
unless(-e "$backup_file.pag") {
    copy("$seen_file.pag","$backup_file.pag");
    copy("$seen_file.dir","$backup_file.dir");
}

my %seen;
tie %seen, "SDBM_File", $seen_file, O_CREAT|O_RDWR, 0644 || die "Can't tie to $seen_file, $!\n";
my $twit;

# set your own username and password here
my $user = 'EeyoresTweeting';
&login;

sub login {
	my $password = 'GreyandFurry';
  	$twit = Net::Twitter::Lite::WithAPIv1_1->new(
      		traits   => [qw/OAuth API::RESTv1_1 API::Search/], 
      		consumer_key        => "blah",
      		consumer_secret     => 'blahblablablablablablablablablabla',
      		access_token        => 'blha-blah',
      		access_token_secret => 'blah'

  	);
 	unless ( 0 || $twit->authorized ) {
  		# The client is not yet authorized: Do it now
    		print "Authorize this app at ", $twit->get_authorization_url, " and enter the PIN#\n";

 			#die;
      		my $pin = <STDIN>; # wait for input
      		chomp $pin;

      		my($access_token, $access_token_secret, $user_id, $screen_name) = $twit->request_access_token(verifier => $pin);
      		warn join "\n",  $access_token, $access_token_secret; # if necessary
	}
}


die "unauthorized" unless $twit->authorized;

# find replies
my $retweets = [];
my $twit_replies = $twit->mentions({since => $dt, count=>100}) ;
my $reply_count=0;
$seen_this_time{$user}=1; # dont tweet at self

#foreach my $reply (@{ $twit_replies }) {
  #my $text = $reply->{'text'};
  #my $id = $reply->{'id'};
  #last if $reply_count == 3;
  #my $name = $reply->{'user'}->{'screen_name'};
  ##print ".";
  #warn "hi -- $text";
  #if($text =~ m/eeyore/  && ! $seen{$id} ){
	##pick a random quote from the collection and @ it
	#my $msg= &random_tweet(\@to_eeyore);
	#next if $msg =~ m#morning# and $localtime[2] > 11;
	#$msg=~ s#XXX#$reply->{'name'}#;
	#warn $msg unless $tweeting_enabled;
	#next if $name=~ /habarosen/i; # another bot
	#next if $name=~ /tigger/i; # another bot
	#next if $name=~ /eeyore/i; # another bot
	#next if $name=~ /disney/i; # another bot
	#next if $seen_this_time{$name};
	#$seen_this_time{$name}=1;
  	#$twit->update($msg,{ in_reply_to_status_id => $id}) if $tweeting_enabled;
  	##warn "would_tweet $msg";
  	#$seen{$id} = 1 ;
  #}
  sleep (13 * 60); # 13 mins.
  $reply_count++;
#
#}


if ($reply_count < 3) {
	my $twit_replies = $twit->search("eeyore");
	# pick a generic quote and tweet it.	
	for my $status ( @{$twit_replies->{'statuses'}} ) {
		next if $status->{text} !~ /^(\@\w+)/;
		my $target_user= $1;
  		next if $seen{$status->{'id'}};
  		$seen{$status->{'id'}} = 1 ;
  		last if $reply_count == 3;
		next if $seen_this_time{$target_user};
		if (defined $seen{$target_user} == $year) {
			next if $seen{$target_user} == $year ;
		}
		$seen{$target_user}= $year;
		$reply_count++;


		my $msg= &random_tweet(\@quotes);
		if ($msg=~ s#XXX#$target_user#) {
			# name embedded in msg now
		} else {
			$msg= "$target_user $msg";
		}
		next if $msg =~ m#morning# and $localtime[2] > 11;
		#warn "generics would tweet: $msg;"; next;
		warn $msg unless $tweeting_enabled;
		my $replyid= $status->{'in_reply_to_status_id'} || $status->{'id'};
		next if $target_user=~ /habarosen/i; # another bot
		next if $target_user=~ /eeyore/i; # another bot
		next if $target_user=~ /tigger/i; # another bot
		next if $target_user=~ /disney/i; # another bot
		#warn $status->{'text'};
		$twit->update({status=>$msg, in_reply_to_status_id => $replyid}) if $tweeting_enabled;
  		sleep (13 * 60 * 10*rand()); # 13 mins.
	}

}

if ($reply_count == 0  and (rand() > 0.5) ){ # if not tweeted yet
	#pick random quote and tweet it
	my $msg= &random_tweet(\@quotes);
	warn $msg unless $tweeting_enabled;
	#warn $msg;
	unless ( $msg =~ m#morning# and $localtime[2] > 11) {
		$twit->update({status=>$msg}) if $tweeting_enabled;
	}
	#warn "would tweet: $msg;"; next;
}


#if (0) {
	#my @followers= $twit->followers_ids;
	#foreach my $f (@followers) {
		#next if defined $seen{"following_".$f};
		#$seen{"following_".$f}++;
		#$twit->create_friend($f);
	#}
#
#
#}




sub random_tweet{
	my $list_ref=shift;
	my @items= @{$list_ref};
	my $index= int(rand() * $#items);
	if (defined $seen_this_time{$items[$index]}) {
		return &random_tweet($list_ref); #new tweet needed
	}
	$seen_this_time{$items[$index]}++;
	return $items[$index];
}

#foreach my $retweet (@{ $retweets }) {
#  print ".";
#  my $status = "(@".$retweet->{'name'}.") ".  $retweet->{'text'};
#  my $code = $twit->update($status);
#  $seen{$retweet->{'id'}} = 1 if $code;
#}
#
#print "\n";


