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
    { name=>'baz', weight=>13, log=>[] }
);


my @timeIntervals=(
    1,   # last second
    3,   # last 3 seconds
    5,   # last 5 seconds
    10,  # last 10 seconds
    30   # last 30 seconds
);


# Printing wastes a lot of time so maybe just print
# every so many events
my $printEvery=10000;


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
my $iter=-1;

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
        my ($x,$log)=@_;
        
        # nothing in the log implies a count of 0
        return 0 if $#$log<0;
        
        my ($first,$last)=(0,$#$log);

        while ($first<=$last){
            my $mid=int(($first+$last)/2);

            if ($x<@{$log}[$mid]->{time}){
                $last=$mid-1;
            }else{
                $first=$mid+1;
            }
        }

        return 0 if $first>$#$log;
        
        @$log-@{$log}[$first]->{count};
    };

    my $i=$chooseWeightedIndex->();

    # At this point the event has "happened"
    $t=tv_interval $t0;



    push @{$events[$i]->{log}},{
        count=> scalar @{$events[$i]->{log}},
        time=> $t
    };



    #usleep (rand(1000));

    next if (++$iter)%$printEvery;

    system("clear");
    print "iter=$iter time=$t - most recent event is a $events[$i]->{name}\n";
    print "\n";
    print "Realtime Counters\n";

    foreach my $event (@events){
        print "$event->{name} [".(scalar @{$event->{log}})." instances] ";

        foreach my $timeInterval (@timeIntervals){
            print "(Last $timeInterval seconds: ".($countSinceTimeX->($t-$timeInterval,$event->{log})).") ";
        }
        print "\n";
    }
}
