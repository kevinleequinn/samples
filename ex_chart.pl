# ex_chart services an AJAX request to draw the user's exercise data on an HTML Canvas

sub ex_chart {
	&Error('Invalid Exercise') unless ( $FORM{'eid'} eq 'vitals' || ($FORM{'eid'} >= 1 && $FORM{'eid'} eq int($FORM{'eid'})) );
	my( $query, $sth, $res, $exercise_type, $vetv );

	my $eid = $FORM{eid};
	my $View_Type = $FORM{'t'} >= 1 ? int $FORM{'t'} : 1;
	my $Data_Set = $FORM{'d'} >= 1 ? int $FORM{'d'} : 0;
	my $Overlay = $FORM{'o'} >= 1 ? int $FORM{'o'} : 0;
	my $Week_Offset = $FORM{'w'} =~ /^-?\d+$/ ? int $FORM{'w'} : 0;
	&Error("Week Offset is out of range. ($Week_Offset)")
		unless ( $Week_Offset > -999 && $Week_Offset < 999 );
	my( $total_graph_w, $total_graph_h ) = ( 200,200 );
	( $total_graph_w, $total_graph_h ) = split(/:/,$FORM{'gy'},2)
		if ( $FORM{'gy'} =~ /^\d+:\d+$/ );

	my $NUM_WEEKS = 6;
	if ( $View_Type == 2 ) {
		$NUM_WEEKS = 12;
	} elsif ( $View_Type == 3 ) {
		$NUM_WEEKS = 52;
		$Data_Set = 4;
	}

	my $end_int = 0 - ($Week_Offset + 1) * 7;
	my $interval = ($NUM_WEEKS * 7) + $end_int;
	$query = qq#
SELECT DATE_FORMAT( SUBDATE(NOW(),INTERVAL $interval DAY), '%Y-%m-%e' )
     , DAYOFWEEK( SUBDATE(NOW(),INTERVAL $interval DAY) )
     , DATE_FORMAT( SUBDATE(NOW(),INTERVAL $interval DAY), '%b %D ''%y' )
     , DATE_FORMAT( SUBDATE(NOW(),INTERVAL $end_int DAY), '%b %D ''%y' )
#;
	&Error('Can\'t get Dates') unless ( $sth = &BW_SQL($query) );
	$res = $sth->fetchrow_arrayref;
	my $start_date = $$res[0];
	my $head_start = $$res[2];
	my $head_end = $$res[3];

	if ( $$res[1] > 1 ) {
		my $interval = $$res[1] - 1;
		$query = qq#
SELECT DATE_FORMAT( SUBDATE('$start_date',INTERVAL $interval DAY), '%Y-%m-%e' )
     , DATE_FORMAT( SUBDATE('$start_date',INTERVAL $interval DAY), '%b %D ''%y' )
#;
		&Error('Can\'t get Dates') unless ( $sth = &BW_SQL($query) );
		$res = $sth->fetchrow_arrayref;
		$start_date = $$res[0];
		$head_start = $$res[1];
	}

	if ( substr($head_start,-2,2) eq substr($head_end,-2,2) ) {
		$head_start = substr($head_start,0,-4);
		$head_end = substr($head_end,0,-3) . '&nbsp;' . substr($head_end,-4,4);
	}

	open( FILE, "../gyms/$GYM_ID/templates/css/images/ofc_chart.colors" );
	my @colors = <FILE>;
	close( FILE );

	my $linecolor = substr(shift @colors,0,7);
	my $backcolor = substr(shift @colors,0,7);
	my $gridcolor = substr(shift @colors,0,7);
	$Colors{1} = $Colors{3} = substr(shift @colors,0,7);
	$Colors{2} = $Colors{4} = substr(shift @colors,0,7);
	$Colors{5} = substr(shift @colors,0,7);
	$Colors{6} = substr(shift @colors,0,7);
	$Colors{7} = substr(shift @colors,0,7);

	if ( $eid eq 'vitals' ) {
		my @vitals = qw( undef height weight bmi bmr heart_rate_Diastolic heart_rate_Systolic heart_rate_Resting vo2_max body_fat fat_mass fat_mass_free body_water cir_calf cir_calfL cir_chest cir_thigh cir_thighL cir_hip cir_upper_arm cir_upper_armL cir_waist );
		my %vdesc = ( 'height', 'Height',
			      'weight', 'Weight',
			      'bmi', 'BMI',
			      'bmr', 'BMR',
			      'heart_rate_Diastolic', 'Diastolic',
			      'heart_rate_Systolic', 'Systolic',
			      'heart_rate_Resting', 'Resting',
                              'vo2_max', 'VO2 Max',
			      'body_fat', 'Body Fat',
			      'fat_mass', 'Fat Mass',
                              'fat_mass_free', 'Free Fat Mass',
			      'body_water', 'Body Water',
			      'cir_calf', 'Calf Circ.',
			      'cir_calfL', 'L Calf Circ.',
			      'cir_chest', 'Chest Circ.',
			      'cir_thigh', 'Thigh Circ.',
			      'cir_thighL', 'L Thigh Circ.',
			      'cir_hip', 'Hip Circ.',
			      'cir_upper_arm', 'Upper Arm Circ.',
			      'cir_upper_armL', 'L Upper Arm Circ.',
			      'cir_waist', 'Waist Circ.' );
		my %vlong = ( 'weight', 'Weight', 'body_fat', 'Body Fat %' );
		$Overlay = $vitals[int($FORM{'d'}.$FORM{'o'})];
		$Colors{'weight'} = $Colors{1};
		$Colors{'body_fat'} = $Colors{2};
		$Colors{$Overlay} = $Colors{5};
		my $ctrv = ($total_graph_w/2) - (295/2);
#		$vetv = "drawImage(document.getElementById('vetv'),$ctrv,0);";
		my $i = 1;
		foreach my $idx ( 'weight', 'body_fat', $Overlay )
		{
			$Labels{$idx}{'sort'} = $i;
			$Labels{$idx}{'desc'} = $vdesc{$idx};
			$Labels{$idx}{'long'} = $vlong{$idx};
			$Last_Val{$idx}{'x'} = -999;
			++$i;
		}
	} else {
		$query = qq#
SELECT exl.label_id, exl.sort_order, rl.short_desc, rl.long_desc, ex.exercise_type_id
FROM EXERCISE_LABELS AS exl
	LEFT JOIN REF_LABELS AS rl ON(exl.label_id=rl.label_id)
	LEFT JOIN EXERCISES AS ex ON(exl.exercise_id=ex.exercise_id)
WHERE exl.exercise_id = $eid
ORDER BY exl.label_id
#;
		&Error('Exercise Not Found') unless ( $sth = &BW_SQL($query) );
		while ( $res = $sth->fetchrow_arrayref )
		{
			$Labels{ $$res[0] }{'sort'} = $$res[1];
			$Labels{ $$res[0] }{'desc'} = $$res[2];
			$Labels{ $$res[0] }{'long'} = $$res[3];
			$Last_Val{ $$res[0] }{'x'} = -999;
			$exercise_type = $$res[4];
		}
	}

	my( $legen1, $legen2, $lglbl1, $lglbl2 );
	if ( $eid eq 'vitals' ) {
		$legen1 = $Colors{1};
		$legen2 = $Colors{2};
		$lglbl1 = $Labels{'weight'}{'long'};
		$lglbl2 = $Labels{'body_fat'}{'long'};
	} elsif ( $exercise_type == 1 || $exercise_type == 3 ) {
		$legen1 = $Colors{2};
		$legen2 = $Colors{1};
		$lglbl1 = $Labels{2}{'long'};
		$lglbl2 = $Labels{1}{'long'};
	} else {
		$legen1 = $Colors{3};
		$legen2 = $Colors{4};
		$lglbl1 = $Labels{3}{'long'};
		$lglbl2 = $Labels{4}{'long'};
	}

	my $divs = qq#
	var ontop = document.getElementById("x_$eid");
	while( ontop.hasChildNodes() ) { ontop.removeChild( ontop.lastChild ); }
#;
	my $ctx = qq#
var heading = document.getElementById("h$eid");
heading.innerHTML = "$head_start &nbsp;to&nbsp; $head_end";
document.getElementById("l_$eid").innerHTML = "<span style='background-color: $legen1;'>&nbsp;&nbsp;&nbsp;</span>&nbsp;$lglbl1 <span style='background-color: $legen2; margin-left: 75px;'>&nbsp;&nbsp;&nbsp;</span>&nbsp;$lglbl2";

var canvas = document.getElementById("cht_$eid");
if (canvas.getContext) {
 var ctx = canvas.getContext("2d");
 with (ctx) {
	clearRect(0, 0, canvas.width, canvas.height);
	lineWidth=1;
	lineCap="round";
	lineJoin="round";
$vetv#;
	my $x_pos = 0;
	my $y_pos = 0;
	my $x_axis = 5;
	my $graph_w = $total_graph_w - ( $x_axis * 2 );
	my $top_h = 1;
	my $bottom_h = 10;
	my $graph_h = $total_graph_h - ( $top_h + $bottom_h );
	my $week_w = int( ($graph_w + 2) / $NUM_WEEKS );

	my $roll_cnt = 1;
	&set_scales($eid);
	if ( $eid eq 'vitals' ) {
		&get_vitals($eid,$NUM_WEEKS,$Overlay,$start_date);
	} else {
		&get_data_set($eid,$NUM_WEEKS,$Data_Set,$start_date);
	}

	# draw the x-axis and baseline
	my @Mon = qw ( tmp JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC );
	my $x_pos += $x_axis + 2;
	my $last_month = 0;
	my $tick_pos = $x_pos;
	my $x_line = $total_graph_h-$bottom_h+1;
	$ctx .= qq#
	fillStyle="$gridcolor";
#;
	foreach my $week_num ( sort byNum keys %Index_Order ) {
		$ctx .= qq#
	fillRect($tick_pos,$x_line,1,1);
#;
		unless ( $Month_Label{$week_num} == $last_month ) {
			my $top = $total_graph_h-$bottom_h+6 . 'px';
			my $left = ( $tick_pos + 4 ) . 'px';
			$divs .= qq#
	var xdiv = document.createElement("div");
	xdiv.setAttribute("class","cht_x");
	xdiv.innerHTML = "$Mon[$Month_Label{$week_num}]";
	xdiv.style.top = "$top";
	xdiv.style.left = "$left";
	xdiv.style.color = "$gridcolor";
	ontop.appendChild(xdiv);
#;
			$last_month = $Month_Label{$week_num};
		}
		$tick_pos += $week_w;
	}
	$ctx .= qq#
	fillRect($tick_pos,$x_line,1,1);
	fillRect($x_axis,$total_graph_h-$bottom_h,$tick_pos,1);
#;

	foreach my $week_num ( sort byNum keys %Index_Order ) {
		my $div_t = $top_h . 'px';
		my $mn = $Month_Label{$week_num};
		my $idx = $Index_Order{$week_num};
		my $num_per_week = scalar keys %{ $Data{$idx} };

		if ( $num_per_week >= 1 ) {
			my $div_w = int($week_w / $num_per_week) - 1;
			my $paddiv = $week_w - ($div_w * $num_per_week) - 1;
			my $div_h = ( $total_graph_h - $bottom_h + 2 ) . 'px';
			my $row_w = int( ($week_w / $num_per_week) / 2 );
			my $padbar =  $week_w - ($row_w * 2 * $num_per_week);
			foreach my $day ( sort { $a <=> $b; } keys %{ $Data{$idx} } )
			{
				my $div_l = ( $x_pos + 4 ) . 'px';
				my $rolltext .= "<b>$Day_Hold{$idx}{$day}{'format'}</b><br>(actual/target)<br>";

				my $label_cnt = 0;
				foreach my $label_id ( sort byLabel keys %Labels )
				{
					$label_cnt++;
					my $row_x = $row_w;
					if ( $padbar > 2 ) { $row_x += 2; $padbar -= 2; }
					elsif ( $padbar > 0 ) { $row_x += 1; --$padbar; }
					my $max = $Labels{$label_id}{'max'};
					my $y_data = $Data{$idx}{$day}{$label_id}{'data'};
					my $y_target = $Data{$idx}{$day}{$label_id}{'target'};
					$rolltext .= "$Labels{$label_id}{desc}: $y_data/$y_target<br>"
						unless ( $y_data == 0 && $y_target == 0 );

					if ( $label_cnt <= 2 )
					{
						if ( $max == 0 ) { $x_pos += $row_x; next; }
						my $dest_x = $x_pos +1;
						my $dest_w = $row_x -1;
						my $dest_y = $top_h + $graph_h - int( ($y_data/$max) * $graph_h );
						$dest_y = $top_h if ( $dest_y < $top_h );
						my $dest_h = $graph_h - $dest_y;
						$ctx .= qq#
	fillStyle="$Colors{$label_id}";
	fillRect($dest_x,$dest_y,$dest_w,$dest_h);
# if ( $dest_h > 0 );
						if ( $y_target > 0 ) {
							my $dash_y = $top_h + $graph_h - int( ($y_target/$max) * $graph_h );
							$dash_y = $top_h if ( $dash_y < $top_h );
							my $dash_w = 2;
							$ctx .= qq#
	fillStyle="$linecolor";
#;
							while ( $dest_x <= ($x_pos+1) + ($dest_w - ($dash_w * 2)) ) {
								$ctx .= qq#
	fillRect($dest_x,$dash_y,$dash_w,1);
#;
								$dest_x += $dash_w * 2;
							}
							if ( $dest_x < ($x_pos+1) + $dest_w ) {
								$dash_w = ( ($x_pos+1) + $dest_w ) - $dest_x < $dash_w ? ( ($x_pos+1) + $dest_w ) - $dest_x : $dash_w;
								$ctx .= qq#
	fillRect($dest_x,$dash_y,$dash_w,1);
#;
							}
						}
						$x_pos += $row_x;
					} else {
						next if ( $y_data == 0 || $max == 0 );
						next unless ( $Overlay == $label_id );
						my $dest_x = $x_pos - $row_w;
						my $dest_y = $top_h + $graph_h - int( ($y_data/$max) * $graph_h );
						next if ( $dest_y < $top_h );

						$ctx .= qq#
	strokeStyle="$Colors{$label_id}";
	beginPath();
	moveTo($Last_Val{$label_id}{'x'},$Last_Val{$label_id}{'y'});
	lineTo($dest_x,$dest_y);
	closePath();
	stroke();
# if ( $Last_Val{$label_id}{'x'} != -999 );
						$ctx .= qq#
	fillStyle="$Colors{$label_id}";
	fillRect($dest_x-1,$dest_y-2,4,4);
#;
						$Last_Val{$label_id}{'x'} = $dest_x;
						$Last_Val{$label_id}{'y'} = $dest_y;
					}
				}
				my $tmp_w = $div_w + $paddiv . 'px';
	                        $divs .= qq#
	var xdiv = document.createElement("a");
	xdiv.setAttribute("href","\#");
	xdiv.setAttribute("class","cht_d");
	xdiv.setAttribute("target","_cht_d$eid");
	xdiv.style.top = "$div_t";
	xdiv.style.left = "$div_l";
	xdiv.style.width = "$tmp_w";
	xdiv.style.height = "$div_h";
	xdiv.setAttribute("tip","$rolltext");
	ontop.appendChild(xdiv);
#;
				$paddiv = 0;
				++$roll_cnt;
			}
		} else {
			## Didn't exercise this week
			$x_pos += $week_w;
		}
	}
	$divs .= qq#
	var xdiv = document.createElement("div");
	xdiv.setAttribute("id","cht_r$eid");
	xdiv.setAttribute("class","cht_r");
	xdiv.setAttribute("onclick","this.style.display='none'; clearTimeout(dis_pop);");
	ontop.appendChild(xdiv);
#;
	$ctx =~ s/\n//g; $divs =~ s/\n//g;
	use Compress::Zlib;
	my $bundle = Compress::Zlib::memGzip('1'.$ctx.' }'.$divs.'}');
	my $length = length($bundle);
	my $origin = "Access-Control-Allow-Origin: *\n" if ( $IPHONEMKT == 1 );
	print "Content-Type: application/x-javascript\nContent-Encoding: gzip\nContent-Length: $length\nExpires: 0\nPragma: no-cache\nCache-Control: no-cache, must-revalidate, no-store\n$origin\n" . $bundle;
	exit;
}
