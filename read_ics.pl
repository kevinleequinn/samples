# read_ics is a rudimentary ICS file reader

sub read_ics {
	if ( -r $_[0] ) {
		my $prefix = $_[1];
		my $limit = $_[2] > 0 ? $_[2] : 30;
		my( $event, $str );
		my $i = 1;
		open(FILE,$_[0]);
		while (<FILE>) {
			last if ( $i > $limit );
			$_ =~ s/\s+$//;
			if ( $_ eq 'BEGIN:VEVENT' ) {
				undef $event;
				$event->{'id'} = $i;
			} elsif ( $_ eq 'END:VEVENT' ) {
				next unless ( $event->{'description'} );
				$event->{'today'} = $prefix;
				my $copy = $TAG{'ICAL:LIST:ITEM'};
				$copy =~ s/~3#([^#]+)#/$event->{$1}/g;
				$str .= $copy;
				++$i;
#			} elsif ( $_ =~ /^DTSTART;TZID=America\/Denver:20110615T110000$/ ) {
			} elsif ( $_ =~ /^DTSTART;VALUE=DATE:(.*)$/ ) {
				if ( $1 =~ /^(\d\d\d\d)(\d\d)(\d\d)$/ ) {
					my( $yr, $mo, $dy ) = ( $1,$2,$3 );
					my $mon = $Mon[int $mo];
					my $dow = &get_day($dy,$mo,$yr);
					$event->{'timestamp'} = "$dow $mon $dy";
				}
			} elsif ( $_ =~ /^DTSTART;TZID=(.*)$/ ) {
				if ( $1 =~ /^[^:]+:(\d\d\d\d)(\d\d)(\d\d)T(\d\d)(\d\d)\d\d$/ ) {
					my( $yr, $mo, $dy, $hr, $mn ) = ( $1,$2,$3,$4,$5 );
					my $mon = $Mon[int $mo];
					my $hour = int $hr;
					my $mer = $hour < 12 ? 'am' : 'pm';
					my $dow = &get_day($dy,$mo,$yr);
					$hour -= 12 if ( $hour > 12 );
					$hour = 12 if ( $hour == 0 );
					$event->{'timestamp'} = "$dow $mon $dy at $hour:$mn$mer";
				}
			} elsif ( $_ =~ /^DTSTART:(.*)$/ ) {
				if ( $1 =~ /^(\d\d\d\d)(\d\d)(\d\d)T(\d\d)(\d\d)\d\dZ$/ ) {
					my( $yr, $mo, $dy, $hr, $mn ) = ( $1,$2,$3,$4,$5 );
					my $mon = $Mon[int $mo];
					my $hour = int $hr;
					my $mer = $hour < 12 ? 'am' : 'pm';
					my $dow = &get_day($dy,$mo,$yr);
					$hour -= 12 if ( $hour > 12 );
					$hour = 12 if ( $hour == 0 );
					$event->{'timestamp'} = "$dow $mon $dy at $hour:$mn$mer";
				}
			} elsif ( $_ =~ /^DTEND;TZID=(.*)$/ ) {
				if ( $1 =~ /^[^:]+:(\d\d\d\d)(\d\d)(\d\d)T(\d\d)(\d\d)\d\d$/ ) {
					my( $yr, $mo, $dy, $hr, $mn ) = ( $1,$2,$3,$4,$5 );
					my $hour = int $hr;
					my $mer = $hour < 12 ? 'am' : 'pm';
					$hour -= 12 if ( $hour > 12 );
					$hour = 12 if ( $hour == 0 );
					$event->{'timestamp'} .= " - $hour:$mn$mer";
				}
			} elsif ( $_ =~ /^DTEND:(.*)$/ ) {
				if ( $1 =~ /^(\d\d\d\d)(\d\d)(\d\d)T(\d\d)(\d\d)\d\dZ$/ ) {
					my( $yr, $mo, $dy, $hr, $mn ) = ( $1,$2,$3,$4,$5 );
					my $hour = int $hr;
					my $mer = $hour < 12 ? 'am' : 'pm';
					$hour -= 12 if ( $hour > 12 );
					$hour = 12 if ( $hour == 0 );
					$event->{'timestamp'} .= " - $hour:$mn$mer";
				}
#			} elsif ( $_ =~ /^DTSTAMP:(.*)$/ ) {
#			} elsif ( $_ =~ /^UID:(.*)$/ ) {
#			} elsif ( $_ =~ /^CREATED:(\d+)Z$/ ) {
			} elsif ( $_ =~ /^DESCRIPTION:(.*)$/ ) {
				my $v2 = $1;
				$v2 =~ s/\\n/<br>/g;
				$v2 =~ s/\\;/;/g;
				$v2 =~ s/\\,/,/g;
				$v2 =~ s/&amp;amp<br>/&amp; /g;
				$v2 =~ s/&amp;nbsp$//g;
				$v2 =~ s/&amp;nbsp<br>/&nbsp;/g;
				$v2 =~ s/&amp;/&/g;
				$event->{'description'} = &htmlify($v2);
			} elsif ( $_ =~ /^LOCATION:(.*)$/ ) {
				$event->{'location'} = &htmlify($1);
			} elsif ( $_ =~ /^SUMMARY:(.*)$/ ) {
				$event->{'summary'} = &htmlify($1);
			} elsif ( $_ =~ /^URL:(.*)$/ ) {
				$event->{'url'} = substr($1,0,3) eq 'www' ? 'http://' . $1 : $1;
#			} elsif ( $_ =~ /^STATUS:(.*)$/ ) {
			}
		}
		close(FILE);

		return $str;
	}
}
