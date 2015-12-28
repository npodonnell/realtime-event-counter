#!/usr/bin/perl
#
# Highly effecient real-time event counting algorithm
# Noel P O'Donnell , 2015

use strict;
use warnings;
use Time::HiRes qw(usleep gettimeofday tv_interval);
use Data::Dumper;


my @events=(
    { name=>'foo', weight=>1, log=>[] },
    { name=>'bar', weight=>3, log=>[] },
    { name=>'baz', weight=>13, log=>[] },
    { name=>'fizz', weight=>11, log=>[] },
    { name=>'buzz', weight=>6, log=>[] },
    { name=>'booze', weight=>15, log=>[] }
);


my @timeIntervals=(
    1,   # last second
    3,   # last 3 seconds
    5,   # last 5 seconds
    10,  # last 10 seconds
    30,  # last 30 seconds
    60,  # last minute
    300, # last 5 mins
    900  # last 15 mins
);


# Convert weights into partitions to make choosing a random
# but weighted event have O(log N)complexity
my $upperLimit=0;

foreach (@events){
    $upperLimit+=$_->{weight};
    $_->{weight}=$upperLimit;
}

# t0 denotes the time at which we begin getting events,
# t denotes the number of seconds elapsed after t0
my $t0=[gettimeofday];
my $t=0.000;

while (1){

    my $chooseWeightedIndex=sub{
        #
        # Choose using binary search
        #
        my ($choice,$first,$last)=(rand($upperLimit),0,$#events);

        while ($first<=$last){
            my $mid=int(($first+$last)/2);

            if ($choice<$events[$mid]->{weight}){
                $last=$mid-1;
            }else{
                $first=$mid+1;
            }
        }

        $first;
    };

    my $countSinceTimeX=sub{
        my ($x,@log)=@_;

        # nothing in the log implies a count of 0
        return 0 if $#log<0;
        
        my ($first,$last)=(0,$#log);

        while ($first<=$last){
            my $mid=int(($first+$last)/2);

            if ($x<$log[$mid]->{time}){
                $last=$mid-1;
            }else{
                $first=$mid+1;
            }
        }

        return 0 if $first>$#log;
        (scalar @log)-($log[$first]->{count});
    };

    my $i=$chooseWeightedIndex->();
    $t=tv_interval $t0;

    system("clear");
    print "t=$t .. $events[$i]->{name}\n";

    push @{$events[$i]->{log}},{
        count=> scalar @{$events[$i]->{log}},
        time=> $t
    };

    foreach my $event (@events){
        print "$event->{name} [".(scalar @{$event->{log}})." instances] ";

        foreach my $timeInterval (@timeIntervals){
            print "(Last $timeInterval seconds: ".($countSinceTimeX->($t-$timeInterval, @{$event->{log}})).") ";
        }
        print "\n";

    }

    usleep (rand(1000000));
}
