# gym_report generates the data for each of the gyms in the system

sub gym_report {
	my( $gym_id ) = $_[0];
	my( $for_period ) = $_[1];
	my( $query, $res, $sth, $data, $str );

	$for_period = ($for_period eq ''?'CURDATE()':"'$for_period'");

	$query = qq#
SELECT ug.user_id, ug.gym_id, g.gym_name, n.nation_id, n.nation
	, CONCAT(u.user_first_name,' ',u.user_last_name) as primary_contact
	, gm.pt_sales_goal as gym_sales_goal
	, gm.pt_conducted_goal as gym_conducted_goal
	, DATE_FORMAT($for_period,'%M') AS month_name
	, EXTRACT(YEAR_MONTH FROM $for_period) as ym
	, CONCAT(ROUND((DAYOFMONTH($for_period)/DATE_FORMAT(DATE_SUB(CONCAT(YEAR($for_period),'-',DATE_FORMAT($for_period,'%m')+1,'-1'), INTERVAL 1 DAY),'%d'))*100),'%') AS percent_complete
	, (gm.pt_sales_goal/(DATE_FORMAT(DATE_SUB(CONCAT(YEAR($for_period),'-',DATE_FORMAT($for_period,'%m')+1,'-1'), INTERVAL 1 DAY),'%d')))*DATE_FORMAT($for_period,'%d') AS mtd_sales_goal
	, (gm.pt_conducted_goal/(DATE_FORMAT(DATE_SUB(CONCAT(YEAR($for_period),'-',DATE_FORMAT($for_period,'%m')+1,'-1'), INTERVAL 1 DAY),'%d')))*DATE_FORMAT($for_period,'%d') AS mtd_conducted_goal
FROM USER_GYM as ug
	LEFT JOIN USERS as u ON(ug.user_id=u.user_id)
	LEFT JOIN REF_NATIONS as n ON(u.nation_id=n.nation_id)
	LEFT JOIN GYMS as g ON(ug.gym_id=g.gym_id)
	LEFT JOIN GYM_MODS as gm ON(ug.gym_id=gm.gym_id)
WHERE ug.gym_id = $gym_id
	AND ug.user_type_id = 200
#;
	return $TAG{"MGMT:GYM:REPORT:NONE"} unless ( $sth = &BW_SQL($query) );
	$res = $sth->fetchrow_hashref;
	my %swap = %$res;

	my( undef, $tznow ) = &get_adjusted_now( $swap{'user_id'} );
	my $lastsecond;
	if ( $for_period eq 'CURDATE()' ) {
		$lastsecond = 'NOW()';
	} else {
		$lastsecond = $for_period;
		$lastsecond =~ s/\'$/ 23:59:59\'/;
	}
	my $sth = &BW_SQL("SELECT DATE_FORMAT('$tznow','%e-%b-%y %l:%i%p')");
	my $res = $sth->fetchrow_arrayref;
	$swap{'today'} = $res->[0];
	( $swap{'today'}, undef ) = split(/\s/,$res->[0],2) unless ( $for_period eq 'CURDATE()' );

	$query = qq#
SELECT u.user_id, u.user_first_name, u.user_last_name
FROM PREFERENCES as p
	LEFT JOIN USER_GYM as ug ON(p.user_id=ug.user_id AND ug.gym_id=p.defaultgym_idx)
	LEFT JOIN USERS as u ON(p.user_id=u.user_id)
WHERE p.defaultgym_idx = $gym_id
	AND ug.user_type_id >= 100
	AND ug.user_type_id < 200
	AND u.user_id NOT IN ( 6 )
	AND (u.memo IS NULL OR u.memo NOT LIKE '%(TERMINATED)%')
ORDER BY u.user_first_name, u.user_last_name
#;
	return $TAG{"MGMT:GYM:REPORT:NONE"} unless ( $sth = &BW_SQL($query) );
	my @trainers;
	while ( $res = $sth->fetchrow_arrayref ) {
		push(@trainers,$res->[0]);
		$data->{$res->[0]}{'user_first_name'} = $res->[1];
		$data->{$res->[0]}{'user_last_name'} = $res->[2];
		$query = qq#
SELECT tm.trainer_type_rate, tm.employee_id, tt.formula, tt.title
FROM TRAINER_MODS as tm
	LEFT JOIN TRAINER_TYPES as tt ON(tm.trainer_type_rate=tt.trainer_type_id)
WHERE tm.trainer_id=$res->[0] AND tm.gym_id=$gym_id
ORDER BY tm.trainer_mod_id DESC LIMIT 1
#;
		my $stha;
		if ( $stha = &BW_SQL($query) ) {
			my $resa = $stha->fetchrow_arrayref;
			$data->{$res->[0]}{'formula'} = $resa->[2];
		}
	}
	my $trainer_ids = join(',',@trainers);

	# get data based on the PUR (purchased) session_type
	$query = qq#
SELECT trainer_id
	, SUM(price) AS pt_sales_actual_price
	, FORMAT(SUM(price),0) AS pt_sales_actual_price_display
	, SUM(qty) AS pt_sales_quantity
FROM TRAINER_SESSIONS
WHERE trainer_id IN( $trainer_ids )
	AND EXTRACT(YEAR_MONTH FROM $for_period) = EXTRACT(YEAR_MONTH FROM session_dt)
	AND session_type IN('PUR','EXP')
	AND product_type != 'BF'
GROUP BY trainer_id
#;
	if ( $sth = &BW_SQL($query) ) {
		while ( $res = $sth->fetchrow_arrayref ) {
			$data->{ $res->[0] }{'trainer_id'} = $res->[0];
			$data->{ $res->[0] }{'pt_sales_actual_price'} = $res->[1];
			$data->{ $res->[0] }{'pt_sales_actual_price_display'} = $res->[2];
			$data->{ $res->[0] }{'pt_sales_quantity'} = $res->[3];
		}
	}

	# get gym's sales not attributed to a trainer
	$query = qq#
SELECT SUM(ts.price) AS pt_sales_notrainer_price
	, SUM(ts.qty) AS pt_sales_notrainer_quantity
	, FORMAT(SUM(ts.price),0) AS pt_sales_notrainer_price_display
FROM TRAINER_SESSIONS AS ts
	LEFT JOIN PREFERENCES p ON (ts.user_id=p.user_id)
WHERE ts.trainer_id = 0
	AND p.defaultgym_idx = $gym_id
	AND EXTRACT(YEAR_MONTH FROM $for_period) = EXTRACT(YEAR_MONTH FROM ts.session_dt)
	AND ts.session_type IN('PUR','EXP')
	AND ts.product_type != 'BF'
#;
	if ( $sth = &BW_SQL($query) ) {
		$res = $sth->fetchrow_arrayref;
		$swap{'pt_sales_notrainer_price'} = $res->[0]?$res->[0]:0;
		$swap{'pt_sales_notrainer_quantity'} = $res->[1]?$res->[1]:0;
		$swap{'pt_sales_notrainer_price_display'} = $res->[2]?$res->[2]:0;
		$swap{'pt_sales_actual_total'} += $swap{'pt_sales_notrainer_price'};
		$swap{'pt_sales_quantity_total'} += $swap{'pt_sales_notrainer_quantity'};
	}

	# get all expired purchases for each client
	$query = qq#
SELECT ut.trainer_id
	, SUM(ts.`left`) as expired_sessions
	, SUM((ts.price/ts.qty)*ts.`left`) as expired_value
FROM USER_TRAINER as ut, TRAINER_SESSIONS as ts
WHERE ut.trainer_id IN( $trainer_ids )
	AND ut.user_id=ts.user_id
	AND ts.session_type = 'EXP'
	AND ts.product_type != 'BF'
	AND EXTRACT(YEAR_MONTH FROM $for_period) = EXTRACT(YEAR_MONTH FROM ts.session_exp)
GROUP BY ut.trainer_id
#;
	if ( $sth = &BW_SQL($query) ) {
		while ( $res = $sth->fetchrow_arrayref ) {
			$data->{ $res->[0] }{'expired_sessions'} = $res->[1] unless ( $res->[1] == 0 );
			$data->{ $res->[0] }{'expired_value'} = $res->[2] unless ( $res->[2] == 0 );
		}
	}

	# get gym's expirations not attributed to a trainer
	$swap{'expired_sessions_notrainer'} = '0';
	$query = qq#
SELECT SUM(ts.`left`) as expired_sessions_notrainer
	, SUM((ts.price/ts.qty)*ts.`left`) as expired_value_notrainer
	, FORMAT(SUM((ts.price/ts.qty)*ts.`left`),0) AS expired_value_notrainer_display
FROM PREFERENCES as p
	LEFT JOIN TRAINER_SESSIONS AS ts ON(p.user_id=ts.user_id)
WHERE p.defaultgym_idx = $gym_id
	AND ts.trainer_id = 0
	AND ts.session_type = 'EXP'
	AND ts.product_type != 'BF'
	AND EXTRACT(YEAR_MONTH FROM $for_period) = EXTRACT(YEAR_MONTH FROM ts.session_exp)
#;
	if ( $sth = &BW_SQL($query) ) {
		$res = $sth->fetchrow_arrayref;
		$swap{'expired_sessions_notrainer'} = $res->[0]?$res->[0]:0;
		$swap{'expired_value_notrainer_display'} = $res->[2]?$res->[2]:0;
		$swap{'expired_sessions_total'} += $res->[0];
		$swap{'expired_value_total'} += $res->[1];
	}

	# use exp_day_query to get all 30day expiry for clients
	$query = qq#
SELECT ut.trainer_id, SUM(ts.`left`) AS expired_sessions_cnt
FROM USER_TRAINER as ut, TRAINER_SESSIONS as ts
WHERE ut.trainer_id IN( $trainer_ids )
	AND ut.user_id=ts.user_id
	AND ts.session_type = 'PUR'
	AND ts.session_exp BETWEEN $for_period AND DATE_ADD($for_period, INTERVAL 30 DAY)
GROUP BY ut.trainer_id
#;
	if ( $sth = &BW_SQL($query) ) {
		while ( $res = $sth->fetchrow_arrayref ) {
			$data->{ $res->[0] }{'expired_sessions_cnt'} = $res->[1] unless ( $res->[1] == 0 );
		}
	}

	# balances either for the last second of the month or now
	if ( $for_period eq 'CURDATE()' ) {
		$query = qq#
SELECT ut.trainer_id
	, SUM(ts.`left`) as balance_left
	, SUM((ts.price/ts.qty)*ts.`left`) as balance_value
FROM USER_TRAINER as ut, TRAINER_SESSIONS as ts
WHERE ut.trainer_id IN( $trainer_ids )
	AND ut.user_id=ts.user_id
	AND ts.session_type='PUR'
GROUP BY ut.trainer_id
#;
		if ( $sth = &BW_SQL($query) ) {
			while ( $res = $sth->fetchrow_arrayref ) {
				$data->{ $res->[0] }{'balance_left'} = $res->[1] unless ( $res->[1] == 0 );
				$data->{ $res->[0] }{'balance_value'} = $res->[2] unless ( $res->[2] == 0 );
				$swap{'balance_left_total'} += $res->[1];
				$swap{'balance_left_value_total'} += $res->[2];
			}
		}
	} else {
		$query = qq#
SELECT ut.trainer_id, ts.session_id, ts.qty, ts.price
FROM USER_TRAINER as ut, TRAINER_SESSIONS as ts
WHERE ut.trainer_id IN( $trainer_ids )
	AND ut.user_id=ts.user_id
	AND ts.session_type IN('PUR','EXP')
	AND ts.session_dt <= $lastsecond
	AND ts.session_exp > $lastsecond
#;
		if ( $sth = &BW_SQL($query) ) {
			while ( $res = $sth->fetchrow_arrayref ) {
				my $stha;
				$query = qq#
SELECT session_id FROM TRAINER_SESSIONS
WHERE `from`=$res->[1]
AND session_type='USE'
AND session_dt<=$lastsecond
#;
				if ( $stha = &BW_SQL($query) ) {
					$left = $res->[2] - $stha->rows;
				} else {
					$left = $res->[2];
				}

				$data->{ $res->[0] }{'balance_left'} += $left unless ( $left == 0 );
				$data->{ $res->[0] }{'balance_value'} += ($res->[2]/$res->[1]) * $left unless ( $left == 0 );
				$swap{'balance_left_total'} += $left;
				$swap{'balance_left_value_total'} += ($res->[2]/$res->[1]) * $left unless ( $left == 0 );
			}
		}
	}

	# get the sales commissions
	$query = qq#
SELECT trainer_id, SUM(comm) AS pt_commission_value
FROM TRAINER_SESSIONS
WHERE trainer_id IN( $trainer_ids )
	AND session_type='PCM'
	AND EXTRACT(YEAR_MONTH FROM $for_period) = EXTRACT(YEAR_MONTH FROM session_dt)
GROUP BY trainer_id
#;
	if ( $sth = &BW_SQL($query) ) {
		while ( $res = $sth->fetchrow_hashref ) {
			next if ( $data->{ $res->{'trainer_id'} }{'formula'} == 1 );
			$data->{ $res->{'trainer_id'} }{'pt_sales_comm_price_display'} = $res->{'pt_commission_value'};
			$data->{ $res->{'trainer_id'} }{'pt_sales_comm_price'} = $res->{'pt_commission_value'};
		}
	}

	# get data based on the USE (conducted) session_type
	$query = qq#
SELECT trainer_id
	, FORMAT(SUM(price/qty),0) AS pt_conducted_value_display
	, SUM(price/qty) AS pt_conducted_value
	, SUM(comm) AS pt_commission_value
	, SUM(qty) AS pt_conducted_quantity
	, SUM(`left`) AS expired_left
FROM TRAINER_SESSIONS
WHERE trainer_id IN( $trainer_ids )
	AND session_type='USE'
	AND EXTRACT(YEAR_MONTH FROM $for_period) = EXTRACT(YEAR_MONTH FROM session_dt)
GROUP BY trainer_id
#;
	if ( $sth = &BW_SQL($query) ) {
		while ( $res = $sth->fetchrow_arrayref ) {
			$data->{ $res->[0] }{'pt_conducted_quantity'}	= $res->[4];
			$data->{ $res->[0] }{'expired_left'} 			= $res->[5];
			$data->{ $res->[0] }{'pt_conducted_value_display'} = &format_number($res->[2]);
			$data->{ $res->[0] }{'pt_conducted_value'}		= $res->[2];
			$data->{ $res->[0] }{'pt_commission_value'}		= $res->[3];
		}
	}

	# count forfeits for each trainer
	$query = qq#
SELECT trainer_id, COUNT(session_id)
FROM TRAINER_SESSIONS
WHERE trainer_id IN( $trainer_ids )
	AND session_type='USE'
	AND session_exp='1999-12-31 23:59:59'
	AND EXTRACT(YEAR_MONTH FROM $for_period) = EXTRACT(YEAR_MONTH FROM session_dt)
GROUP BY trainer_id
#;
#	if ( $sth = &BW_SQL($query) ) {
#		while ( $res = $sth->fetchrow_arrayref ) {
#			$data->{ $res->[0] }{'pt_conducted_noshow_perc'} = $res->[1];
#		}
#	}

	$query = qq#
SELECT trainer_id, COUNT(book_id)
FROM TRAINER_BOOKINGS
WHERE trainer_id IN( $trainer_ids )
	AND ( status=3 OR ( status=1 AND TO_DAYS(book_dt) < TO_DAYS($for_period) ) )
	AND EXTRACT(YEAR_MONTH FROM $for_period) = EXTRACT(YEAR_MONTH FROM book_dt)
GROUP BY trainer_id
#;
	if ( $sth = &BW_SQL($query) ) {
		while ( $res = $sth->fetchrow_arrayref ) {
			$data->{ $res->[0] }{'pt_conducted_noshow_perc'} += $res->[1];
		}
	}

	# get all clients in the last month
	$query = qq#
SELECT ut.trainer_id, COUNT(ut.user_id)
FROM USER_TRAINER as ut
	LEFT JOIN USERS as u ON(ut.user_id=u.user_id)
WHERE ut.trainer_id IN( $trainer_ids )
	AND EXTRACT(YEAR_MONTH FROM $for_period) = EXTRACT(YEAR_MONTH FROM u.start_date)
GROUP BY ut.trainer_id
#;
	if ( $sth = &BW_SQL($query) ) {
		while ( $res = $sth->fetchrow_arrayref ) {
			$data->{ $res->[0] }{'pt_sales_njm_tot'} = $res->[1];
		}
	}
	$query = qq#
SELECT ut.trainer_id, COUNT(DISTINCT ut.user_id)
FROM USER_TRAINER as ut
	LEFT JOIN USERS as u ON(ut.user_id=u.user_id)
	LEFT JOIN TRAINER_SESSIONS as ts ON(ut.user_id=ts.user_id AND ts.session_type IN('PUR','EXP') AND ts.product_type != 'BF')
WHERE ut.trainer_id IN( $trainer_ids )
	AND ts.session_id IS NOT NULL
	AND EXTRACT(YEAR_MONTH FROM $for_period) = EXTRACT(YEAR_MONTH FROM u.start_date)
GROUP BY ut.trainer_id
#;
	if ( $sth = &BW_SQL($query) ) {
		while ( $res = $sth->fetchrow_arrayref ) {
			$data->{ $res->[0] }{'pt_sales_njm_perc'} = $res->[1] / $data->{ $res->[0] }{'pt_sales_njm_tot'} unless ( $data->{ $res->[0] }{'pt_sales_njm_tot'} == 0 );
		}
	}

	# get active clients
	$query = qq#
SELECT trainer_id, COUNT(DISTINCT(user_id))
FROM TRAINER_SESSIONS
WHERE trainer_id IN( $trainer_ids )
	AND EXTRACT(YEAR_MONTH FROM $for_period) = EXTRACT(YEAR_MONTH FROM session_dt)
GROUP BY trainer_id
#;
	if ( $sth = &BW_SQL($query) ) {
		while ( $res = $sth->fetchrow_arrayref ) {
			$data->{ $res->[0] }{'active_clients_cnt'} = $res->[1];
		}
	}

	my $i = 0;
	my %hkcomm = &hk_comm() if ( $swap{'nation_id'} eq 'HKG' );
	foreach my $id ( @trainers )
	{
		my( $stha, $resa );
		my %hash = ( 'user_id', $id, 'user_first_name', $data->{$id}{'user_first_name'}, 'user_last_name', $data->{$id}{'user_last_name'} );

		$query = qq#
SELECT tm.trainer_mod_id, tm.employee_id, tm.trainer_type_rate, tm.pt_sales_goal, FORMAT(tm.pt_sales_goal,0), tm.pt_conducted_goal, FORMAT(tm.pt_conducted_goal,0), tt.nation_id, tt.formula
	, (tm.pt_sales_goal/(DATE_FORMAT(DATE_SUB(CONCAT(YEAR($for_period),'-',DATE_FORMAT($for_period,'%m')+1,'-1'), INTERVAL 1 DAY),'%d')))*DATE_FORMAT($for_period,'%d') AS mtd_sales_goal
	, (tm.pt_conducted_goal/(DATE_FORMAT(DATE_SUB(CONCAT(YEAR($for_period),'-',DATE_FORMAT($for_period,'%m')+1,'-1'), INTERVAL 1 DAY),'%d')))*DATE_FORMAT($for_period,'%d') AS mtd_sales_goal_units
FROM TRAINER_MODS as tm
	LEFT JOIN TRAINER_TYPES as tt ON(tm.trainer_type_rate=tt.trainer_type_id)
WHERE tm.trainer_id=$id AND tm.gym_id=$gym_id AND tm.entry_date < $lastsecond ORDER BY tm.trainer_mod_id DESC LIMIT 1
#;
		if ( $stha = &BW_SQL($query) ) {
			$resa = $stha->fetchrow_arrayref;
			$hash{'trainer_mod_id'} = $resa->[0];
			$hash{'employee_id'} = $resa->[1];
			$hash{'trainer_type_rate'} = $resa->[2];
			$hash{'pt_sales_goal'} = $resa->[3];
			$hash{'pt_sales_goal_display'} = $resa->[4];
			$hash{'pt_conducted_goal'} = $resa->[5];
			$hash{'pt_conducted_goal_display'} = $resa->[6];
			$hash{'nation_id'} = $resa->[7];
			$hash{'formula'} = $resa->[8];
			$hash{'mtd_sales_goal'} = $resa->[9];
			$hash{'mtd_sales_goal_units'} = $resa->[10];
		}

		## overload the $hash, per user/trainer id, and set values from other queries, calculated or otherwise.
		$hash{'trainer_id'}					= $data->{$id}->{'trainer_id'};
		$hash{'pt_sales_actual_price'} 		= $data->{$id}->{'pt_sales_actual_price'}?$data->{$id}->{'pt_sales_actual_price'}:'';
		$hash{'pt_sales_actual_price_display'}	= $data->{$id}->{'pt_sales_actual_price_display'}?$data->{$id}->{'pt_sales_actual_price_display'}:'';
		$hash{'pt_sales_quantity'} 			= $data->{$id}->{'pt_sales_quantity'}?$data->{$id}->{'pt_sales_quantity'}:'';
		$hash{'pt_sales_mtd_perc'}			= $hash{'pt_sales_actual_price'}?&format_percent($hash{'mtd_sales_goal'}==0?"0%":$hash{'pt_sales_actual_price'}/$hash{'mtd_sales_goal'}):'';
		$hash{'pt_sales_perc_goal'} 		= $hash{'pt_sales_goal'}==0?'':&format_percent($hash{'pt_sales_actual_price'}/$hash{'pt_sales_goal'});
		$hash{'pt_sales_njm_perc'}			= $data->{$id}->{'pt_sales_njm_perc'}?&format_percent($data->{$id}->{'pt_sales_njm_perc'}):'';
		$hash{'pt_sales_comm_price'}		= $data->{$id}->{'pt_sales_comm_price'}?$data->{$id}->{'pt_sales_comm_price'}:'';
		$hash{'pt_sales_comm_price_display'}= $data->{$id}->{'pt_sales_comm_price_display'}?&format_number($data->{$id}->{'pt_sales_comm_price_display'}):'';
		$hash{'pt_conducted_quantity'}		= $data->{$id}->{'pt_conducted_quantity'}?$data->{$id}->{'pt_conducted_quantity'}:'';
		$hash{'pt_conducted_mtd_perc'}		= $hash{'pt_conducted_quantity'}?&format_percent($hash{'mtd_sales_goal_units'}==0?"0%":$hash{'pt_conducted_quantity'}/$hash{'mtd_sales_goal_units'}):'';
		$hash{'pt_conducted_perc'} 			= $hash{'pt_conducted_goal'}==0?'':&format_percent($hash{'pt_conducted_quantity'}/$hash{'pt_conducted_goal'});
		$hash{'pt_conducted_value_display'}	= $data->{$id}->{'pt_conducted_value_display'}?$data->{$id}->{'pt_conducted_value_display'}:'';
		$hash{'pt_conducted_noshow_perc'}	= $data->{$id}->{'pt_conducted_noshow_perc'}?&format_percent($hash{'pt_conducted_quantity'}==0?"0%":$data->{$id}{'pt_conducted_noshow_perc'}/$hash{'pt_conducted_quantity'}):'';
		$hash{'balance_left'}	 			= $data->{$id}->{'balance_left'}?$data->{$id}->{'balance_left'}:'';
		$hash{'balance_value'} 				= $data->{$id}->{'balance_value'}?$data->{$id}->{'balance_value'}:'';
		$hash{'expired_sessions'} 			= $data->{$id}->{'expired_sessions'}?$data->{$id}->{'expired_sessions'}:'';
		$hash{'expired_value'} 				= $data->{$id}->{'expired_value'}?&format_number($data->{$id}->{'expired_value'}):'';
		$hash{'expired_sessions_cnt'}		= $data->{$id}->{'expired_sessions_cnt'}?$data->{$id}->{'expired_sessions_cnt'}:'';
		$hash{'active_clients_cnt'}			= $data->{$id}->{'active_clients_cnt'}?$data->{$id}->{'active_clients_cnt'}:'';

		$hash{'pt_sales_goal_display'} = '' if ( $hash{'pt_sales_goal'} == 0 );
		$hash{'pt_conducted_goal_display'} = '' if ( $hash{'pt_conducted_goal'} == 0 );

		## commission calculation
		if ( $hash{'formula'} == 0 ) {
			# just the fixed commission price
			$hash{'pt_commission_value'} = $data->{$id}->{'pt_commission_value'}?&format_number($data->{$id}->{'pt_commission_value'}):'';
			$hash{'gross_commission'} = $data->{$id}->{'pt_sales_comm_price'} + $data->{$id}->{'pt_commission_value'};
		} else {
			$hash{'gross_commission'} = $data->{$id}->{'pt_sales_comm_price'};
			$query = qq#
SELECT ts.price, ts.comm, ts.product_type, tsa.description
FROM TRAINER_SESSIONS as ts
	LEFT JOIN TRAINER_SESSIONS_AUDIT as tsa ON(ts.`from`=tsa.session_id AND tsa.function='adpur')
WHERE ts.trainer_id = $id
AND EXTRACT(YEAR_MONTH FROM $for_period) = EXTRACT(YEAR_MONTH FROM ts.session_dt)
AND ts.session_type = 'USE'
ORDER BY ts.session_dt
#;
			if ( $stha = &BW_SQL($query) ) {
				my $gc_cnt = 1;
				while ( $resa = $stha->fetchrow_arrayref )
				{
					my $commission;

					if ( $resa->[2] eq 'BF' || $resa->[2] eq 'BS' || substr($resa->[3],-3,2) eq '-X' ) {
						$commission = &format_number2($resa->[1]);
					} else {
						my $dollars = $resa->[1];

						if ( $hash{'nation_id'} eq 'HKG' ) {
							my( undef, $desca, $descb ) = split(/\<br\>/,$resa->[3],3);
							if ( $descb =~ /\(([^\)]+)\)$/ ) {
								if ( $hkcomm{$hash{'trainer_type_rate'}}{$1} > 1 ) {
									$dollars = $hkcomm{$hash{'trainer_type_rate'}}{$1};
									$swap{'missing'} .= "$1=$dollars<br>";
								} else {
									$swap{'missing'} .= "Type mismatch with $1, using commission $dollars<br>" unless ( $resa->[2] eq 'BF');
								}
							} elsif ( $desca =~ /\(([^\)]+)\)$/ ) {
								if ( $hkcomm{$hash{'trainer_type_rate'}}{$1} > 1 ) {
									$dollars = $hkcomm{$hash{'trainer_type_rate'}}{$1};
									$swap{'missing'} .= "$1=$dollars<br>";
								} else {
									$swap{'missing'} .= "Type mismatch with $1, using commission $dollars<br>" unless ( $resa->[2] eq 'BF');
								}
							} else {
								$swap{'missing'} .= "Type notfound with $1, using commission $dollars<br>";
							}

						} elsif ( $hash{'formula'} == 1 ) {
							$dollars = $resa->[0];
						}
						$commission = &format_number2($dollars * &comm_multiplier( $hash{'formula'}, $gc_cnt ));
						$gc_cnt++;
					}
					$hash{'pt_commission_value'} += $commission;
					$hash{'gross_commission'} += $commission;
				}
			}
		}
		$hash{'gross_commission'} = '--' if ( $swap{'nation_id'} eq 'HKG' );  # no Hong Kong commissions for now

		## calculate totals, set them into our swap hash
		$swap{'pt_sales_goal_total'} 		+= $hash{'pt_sales_goal'};
		$swap{'pt_sales_comm_total'}		+= $hash{'pt_sales_comm_price'};
		$swap{'pt_conducted_goal_total'}	+= $hash{'pt_conducted_goal'};
		$swap{'pt_commission_value_total'}	+= $hash{'pt_commission_value'};
		$swap{'gross_commission_total'} 	+= $hash{'gross_commission'};
		$swap{'pt_sales_actual_total'} 		+= $hash{'pt_sales_actual_price'};
		$swap{'pt_sales_perc_goal_total'} 	+= $hash{'pt_sales_perc_goal'};
		$swap{'pt_sales_quantity_total'} 	+= $hash{'pt_sales_quantity'};
		$swap{'pt_conducted_quantity_total'}+= $hash{'pt_conducted_quantity'};
		$swap{'pt_conducted_value_total'}	+= $data->{$id}->{'pt_conducted_value'};
		$swap{'expired_sessions_total'}		+= $hash{'expired_sessions'};
		$swap{'expired_value_total'}		+= $data->{$id}->{'expired_value'};
		$swap{'expired_sessions_cnt_total'}	+= $hash{'expired_sessions_cnt'};
		$swap{'active_clients_cnt_total'}	+= $hash{'active_clients_cnt'};

		## format any numbers used in calculations above
		$hash{'pt_sales_comm_price'}=	&format_number($hash{'pt_sales_comm_price'});
		$hash{'pt_commission_value'}=	&format_number($hash{'pt_commission_value'});
		$hash{'gross_commission'}	=	&format_number($hash{'gross_commission'});
		$hash{'balance_value'}		=	&format_number($hash{'balance_value'});

		++$i;
		my( $copy ) = $TAG{"MGMT:GYM:REPORT:ITEM"};
		$TAG{'MGMT:GYM:REPORT:ITEM:LINK'} = $TAG{'MGMT:GYM:REPORT:ITEM:LINK:ARCHIVE'} unless ( $for_period eq 'CURDATE()' ); # KQ.03-20-2006
		$copy =~ s/~5\@(MGMT:GYM:REPORT:ITEM:LINK)\@/$TAG{$1}/;
		$hash{'ym'} = $swap{'ym'};
		$copy =~ s/~4#([^#]+)#/$hash{$1}/g;
		$str .= $copy;
	}

	if ($i>0) {
		$swap{'pt_sales_perc_goal_total'} = $swap{'gym_sales_goal'}==0?'0%':&format_percent($swap{'pt_sales_actual_total'}/$swap{'gym_sales_goal'});
		$swap{'pt_conducted_perc_total'} = $swap{'gym_conducted_goal'}==0?'0%':&format_percent($swap{'pt_conducted_quantity_total'}/$swap{'gym_conducted_goal'});
		$swap{'pt_sales_mtd_perc_total'} = $swap{'mtd_sales_goal'}==0?'0%':&format_percent($swap{'pt_sales_actual_total'}/$swap{'mtd_sales_goal'});
		$swap{'pt_conducted_mtd_perc_total'} = $swap{'mtd_conducted_goal'}==0?'0%':&format_percent($swap{'pt_conducted_quantity_total'}/$swap{'mtd_conducted_goal'});
	} else {
		$swap{'pt_sales_perc_goal_total'} = "0%";
		$swap{'pt_conducted_perc_total'} = "0%";
		$swap{'pt_sales_mtd_perc_total'} = '0%';
		$swap{'pt_conducted_mtd_perc_total'} = '0%';
	}

	# format any totals rows, as needed
	$swap{'gym_sales_goal_total'}			= &format_number($swap{'gym_sales_goal'});
	$swap{'gym_conducted_goal_total'}		= &format_number($swap{'gym_conducted_goal'});
	$swap{'pt_sales_goal_total'}			= &format_number($swap{'pt_sales_goal_total'});
	$swap{'pt_sales_actual_total'}			= &format_number($swap{'pt_sales_actual_total'});
	$swap{'pt_sales_comm_total'}			= &format_number($swap{'pt_sales_comm_total'});
	$swap{'pt_conducted_goal_total'}		= &format_number($swap{'pt_conducted_goal_total'});
	$swap{'pt_conducted_value_total'}		= &format_number($swap{'pt_conducted_value_total'});
	$swap{'pt_commission_value_total'}		= &format_number($swap{'pt_commission_value_total'});
	$swap{'gross_commission_total'}			= &format_number($swap{'gross_commission_total'});
	$swap{'balance_left_total'}				= &format_number($swap{'balance_left_total'});
	$swap{'expired_value_total'}			= &format_number($swap{'expired_value_total'});
	$swap{'active_clients_cnt_total'}		= &format_number($swap{'active_clients_cnt_total'});

	my $table = $TAG{"MGMT:GYM:REPORT"};
	$table =~ s/~4\@MGMT:GYM:REPORT:LIST\@/$str/g;
	$table =~ s/~4\@MGMT:TRAINER:REPORT:MISSING\@/$TAG{'MGMT:TRAINER:REPORT:MISSED'}/ if ( length($swap{'missing'}) > 1 );
	$table =~ s/~3#([^#]+)#/$swap{$1}/g;
	return $table;
}
