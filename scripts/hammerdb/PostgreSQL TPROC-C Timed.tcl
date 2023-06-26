#!/usr/local/bin/tclsh8.6
#EDITABLE OPTIONS##################################################
set library Pgtcl ;# PostgreSQL Library
set total_iterations 10000000 ;# Number of transactions before logging off
set RAISEERROR "false" ;# Exit script on PostgreSQL (true or false)
set KEYANDTHINK "false" ;# Time for user thinking and keying (true or false)
set rampup 3;  # Rampup time in minutes before first Transaction Count is taken
set duration 7;  # Duration in minutes before second Transaction Count is taken
set mode "Local" ;# HammerDB operational mode
set VACUUM "false" ;# Perform checkpoint and vacuum when complete (true or false)
set DRITA_SNAPSHOTS "false";#Take DRITA Snapshots
set ora_compatible "false" ;#Postgres Plus Oracle Compatible Schema
set pg_storedprocs "false" ;#Postgres v11 Stored Procedures
set host "localhost" ;# Address of the server hosting PostgreSQL
set port "5432" ;# Port of the PostgreSQL server
set sslmode "disable" ;# SSLMode of the PostgreSQL Server
set superuser "hirbod" ;# Superuser privilege user
set superuser_password "1234" ;# Password for Superuser
set default_database "postgres" ;# Default Database for Superuser
set user "tpcc" ;# PostgreSQL user
set password "tpcc" ;# Password for the PostgreSQL user
set db "tpcc" ;# Database containing the TPC Schema
#EDITABLE OPTIONS##################################################
#LOAD LIBRARIES AND MODULES
if [catch {package require $library} message] { error "Failed to load $library - $message" }
if [catch {::tcl::tm::path add modules} ] { error "Failed to find modules directory" }
if [catch {package require tpcccommon} ] { error "Failed to load tpcc common functions" } else { namespace import tpcccommon::* }

if { [ chk_thread ] eq "FALSE" } {
    error "PostgreSQL Timed Script must be run in Thread Enabled Interpreter"
}

proc ConnectToPostgres { host port sslmode user password dbname } {
    global tcl_platform
    if {[catch {set lda [pg_connect -conninfo [list host = $host port = $port sslmode = $sslmode user = $user password = $password dbname = $dbname ]]} message]} {
        set lda "Failed" ; puts $message
        error $message
    } else {
        pg_notice_handler $lda puts
        set result [ pg_exec $lda "set CLIENT_MIN_MESSAGES TO 'ERROR'" ]
        pg_result $result -clear
    }
    return $lda
}
set rema [ lassign [ findvuposition ] myposition totalvirtualusers ]
switch $myposition {
    1 { 
        if { $mode eq "Local" || $mode eq "Primary" } {
            if { ($DRITA_SNAPSHOTS eq "true") || ($VACUUM eq "true") } {
                set lda [ ConnectToPostgres $host $port $sslmode $superuser $superuser_password $default_database ]
                if { $lda eq "Failed" } {
                    error "error, the database connection to $host could not be established"
                } 
            }
            set lda1 [ ConnectToPostgres $host $port $sslmode $user $password $db ]
            if { $lda1 eq "Failed" } {
                error "error, the database connection to $host could not be established"
            } 
            set ramptime 0
            puts "Beginning rampup time of $rampup minutes"
            set rampup [ expr $rampup*60000 ]
            while {$ramptime != $rampup} {
                if { [ tsv::get application abort ] } { break } else { after 6000 }
                set ramptime [ expr $ramptime+6000 ]
                if { ![ expr {$ramptime % 60000} ] } {
                    puts "Rampup [ expr $ramptime / 60000 ] minutes complete ..."
                }
            }
            if { [ tsv::get application abort ] } { break }
            if { $DRITA_SNAPSHOTS eq "true" } {
                puts "Rampup complete, Taking start DRITA snapshot."
                set result [pg_exec $lda "select * from edbsnap()" ]
                if {[pg_result $result -status] ni {"PGRES_TUPLES_OK" "PGRES_COMMAND_OK"}} {
                    if { $RAISEERROR } {
                        error "[pg_result $result -error]"
                    } else {
                        puts "DRITA Snapshot Error set RAISEERROR for Details"
                    }
                } else {
                    pg_result $result -clear
                    pg_select $lda {select edb_id,snap_tm from edb$snap order by edb_id desc limit 1} snap_arr {
                        set firstsnap $snap_arr(edb_id)
                        set first_snaptime $snap_arr(snap_tm)
                    }
                    puts "Start Snapshot $firstsnap taken at $first_snaptime"
                }
            } else {
                puts "Rampup complete, Taking start Transaction Count."
            }
            pg_select $lda1 "select sum(xact_commit + xact_rollback) from pg_stat_database" tx_arr {
                set start_trans $tx_arr(sum)
            }
            pg_select $lda1 "select sum(d_next_o_id) from district" o_id_arr {
                set start_nopm $o_id_arr(sum)
            }
            puts "Timing test period of $duration in minutes"
            set testtime 0
            set durmin $duration
            set duration [ expr $duration*60000 ]
            while {$testtime != $duration} {
                if { [ tsv::get application abort ] } { break } else { after 6000 }
                set testtime [ expr $testtime+6000 ]
                if { ![ expr {$testtime % 60000} ] } {
                    puts -nonewline  "[ expr $testtime / 60000 ]  ...,"
                }
            }
            if { [ tsv::get application abort ] } { break }
            if { $DRITA_SNAPSHOTS eq "true" } {
                puts "Test complete, Taking end DRITA snapshot."
                set result [pg_exec $lda "select * from edbsnap()" ]
                if {[pg_result $result -status] ni {"PGRES_TUPLES_OK" "PGRES_COMMAND_OK"}} {
                    if { $RAISEERROR } {
                        error "[pg_result $result -error]"
                    } else {
                        puts "Snapshot Error set RAISEERROR for Details"
                    }
                } else {
                    pg_result $result -clear
                    pg_select $lda {select edb_id,snap_tm from edb$snap order by edb_id desc limit 1} snap_arr  {
                        set endsnap $snap_arr(edb_id)
                        set end_snaptime $snap_arr(snap_tm)
                    }
                    puts "End Snapshot $endsnap taken at $end_snaptime"
                    puts "Test complete: view DRITA report from SNAPID $firstsnap to $endsnap"
                }
            } else {
                puts "Test complete, Taking end Transaction Count."
            }
            pg_select $lda1 "select sum(xact_commit + xact_rollback) from pg_stat_database" tx_arr {
                set end_trans $tx_arr(sum)
            }
            pg_select $lda1 "select sum(d_next_o_id) from district" o_id_arr {
                set end_nopm $o_id_arr(sum)
            }
            set tpm [ expr {($end_trans - $start_trans)/$durmin} ]
            set nopm [ expr {($end_nopm - $start_nopm)/$durmin} ]
            puts "[ expr $totalvirtualusers - 1 ] Active Virtual Users configured"
            puts [ testresult $nopm $tpm PostgreSQL ]
            tsv::set application abort 1
            if { $mode eq "Primary" } { eval [subst {thread::send -async $MASTER { remote_command ed_kill_vusers }}] }
            if { $VACUUM } {
                set RAISEERROR "true"
                puts "Checkpoint and Vacuum"
                set result [pg_exec $lda "checkpoint" ]
                if {[pg_result $result -status] ni {"PGRES_TUPLES_OK" "PGRES_COMMAND_OK"}} {
                    if { $RAISEERROR } {
                        error "[pg_result $result -error]"
                    } else {
                        puts "Checkpoint Error set RAISEERROR for Details"
                    }
                } else {
                    pg_result $result -clear
                }
                set result [pg_exec $lda "vacuum" ]
                if {[pg_result $result -status] ni {"PGRES_TUPLES_OK" "PGRES_COMMAND_OK"}} {
                    if { $RAISEERROR } {
                        error "[pg_result $result -error]"
                    } else {
                        puts "Vacuum Error set RAISEERROR for Details"
                    }
                } else {
                    puts "Checkpoint and Vacuum Complete"
                    pg_result $result -clear
                }
            }
            if { ($DRITA_SNAPSHOTS eq "true") || ($VACUUM eq "true") } {
                pg_disconnect $lda
            }
            pg_disconnect $lda1
        } else {
            puts "Operating in Replica Mode, No Snapshots taken..."
        }
    }
    default {
        #TIMESTAMP
        proc gettimestamp { } {
            set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
            return $tstamp
        }
        #NEW ORDER
        proc neword { lda no_w_id w_id_input RAISEERROR ora_compatible pg_storedprocs } {
            #2.4.1.2 select district id randomly from home warehouse where d_w_id = d_id
            set no_d_id [ RandomNumber 1 10 ]
            #2.4.1.2 Customer id randomly selected where c_d_id = d_id and c_w_id = w_id
            set no_c_id [ RandomNumber 1 3000 ]
            #2.4.1.3 Items in the order randomly selected from 5 to 15
            set ol_cnt [ RandomNumber 5 15 ]
            #2.4.1.6 order entry date O_ENTRY_D generated by SUT
            set date [ gettimestamp ]
            if { $ora_compatible eq "true" } {
                set result [pg_exec $lda "exec neword($no_w_id,$w_id_input,$no_d_id,$no_c_id,$ol_cnt,0,TO_TIMESTAMP($date,'YYYYMMDDHH24MISS'))" ]
            } else {
                if { $pg_storedprocs eq "true" } {
                    set result [pg_exec $lda "call neword($no_w_id,$w_id_input,$no_d_id,$no_c_id,$ol_cnt,0.0,'','',0.0,0.0,0,TO_TIMESTAMP('$date','YYYYMMDDHH24MISS')::timestamp without time zone)" ]
                } else {
                    set result [ pg_exec_prepared $lda neword {} {} $no_w_id $w_id_input $no_d_id $no_c_id $ol_cnt ]
                }
            }
            if {[pg_result $result -status] != "PGRES_TUPLES_OK"} {
                if { $RAISEERROR } {
                    error "[pg_result $result -error]"
                } else {
                    puts "New Order Procedure Error set RAISEERROR for Details"
                }
                pg_result $result -clear
            } else {
                pg_result $result -clear
            }
        }
        #PAYMENT
        proc payment { lda p_w_id w_id_input RAISEERROR ora_compatible pg_storedprocs } {
            #2.5.1.1 The home warehouse id remains the same for each terminal
            #2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
            set p_d_id [ RandomNumber 1 10 ]
            #2.5.1.2 customer selected 60% of time by name and 40% of time by number
            set x [ RandomNumber 1 100 ]
            set y [ RandomNumber 1 100 ]
            if { $x <= 85 } {
                set p_c_d_id $p_d_id
                set p_c_w_id $p_w_id
            } else {
                #use a remote warehouse
                set p_c_d_id [ RandomNumber 1 10 ]
                set p_c_w_id [ RandomNumber 1 $w_id_input ]
                while { ($p_c_w_id == $p_w_id) && ($w_id_input != 1) } {
                    set p_c_w_id [ RandomNumber 1  $w_id_input ]
                }
            }
            set nrnd [ NURand 255 0 999 123 ]
            set name [ randname $nrnd ]
            set p_c_id [ RandomNumber 1 3000 ]
            if { $y <= 60 } {
                #use customer name
                #C_LAST is generated
                set byname 1
            } else {
                #use customer number
                set byname 0
                set name {}
            }
            #2.5.1.3 random amount from 1 to 5000
            set p_h_amount [ RandomNumber 1 5000 ]
            #2.5.1.4 date selected from SUT
            set h_date [ gettimestamp ]
            #2.5.2.1 Payment Transaction
            #change following to correct values
            if { $ora_compatible eq "true" } {
                set result [pg_exec $lda "exec payment($p_w_id,$p_d_id,$p_c_w_id,$p_c_d_id,$p_c_id,$byname,$p_h_amount,'$name','0',0,TO_TIMESTAMP($h_date,'YYYYMMDDHH24MISS'))" ]
            } else {
                if { $pg_storedprocs eq "true" } {
                    set result [pg_exec $lda "call payment($p_w_id,$p_d_id,$p_c_w_id,$p_c_d_id,$byname,$p_h_amount,'0','$name',$p_c_id,'','','','','','','','','','','','','','','','','','',TO_TIMESTAMP('$h_date','YYYYMMDDHH24MISS')::timestamp without time zone,0.0,0.0,0.0,'',TO_TIMESTAMP('$h_date','YYYYMMDDHH24MISS')::timestamp without time zone)" ]
                } else {
                    set result [ pg_exec_prepared $lda payment {} {} $p_w_id $p_d_id $p_c_w_id $p_c_d_id $p_c_id $byname $p_h_amount $name ]
                }
            }
            if {[pg_result $result -status] != "PGRES_TUPLES_OK"} {
                if { $RAISEERROR } {
                    error "[pg_result $result -error]"
                } else {
                    puts "Payment Procedure Error set RAISEERROR for Details"
                }
                pg_result $result -clear
            } else {
                pg_result $result -clear
            }
        }
        #ORDER_STATUS
        proc ostat { lda w_id RAISEERROR ora_compatible pg_storedprocs } {
            #2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
            set d_id [ RandomNumber 1 10 ]
            set nrnd [ NURand 255 0 999 123 ]
            set name [ randname $nrnd ]
            set c_id [ RandomNumber 1 3000 ]
            set y [ RandomNumber 1 100 ]
            if { $y <= 60 } {
                set byname 1
            } else {
                set byname 0
                set name {}
            }
            if { $ora_compatible eq "true" } {
                set result [pg_exec $lda "exec ostat($w_id,$d_id,$c_id,$byname,'$name')" ]
            } else {
                if { $pg_storedprocs eq "true" } {
                    set date [ gettimestamp ]
                    set result [pg_exec $lda "call ostat($w_id,$d_id,$c_id,$byname,'$name','','',0.0,0,TO_TIMESTAMP('$date','YYYYMMDDHH24MISS')::timestamp without time zone,0,'')" ]
                } else {
                    set result [ pg_exec_prepared $lda ostat {} {} $w_id $d_id $c_id $byname $name ]
                }
            }
            if {[pg_result $result -status] != "PGRES_TUPLES_OK"} {
                if { $RAISEERROR } {
                    error "[pg_result $result -error]"
                } else {
                    puts "Order Status Procedure Error set RAISEERROR for Details"
                }
                pg_result $result -clear
            } else {
                pg_result $result -clear
            }
        }
        #DELIVERY
        proc delivery { lda w_id RAISEERROR ora_compatible pg_storedprocs } {
            set carrier_id [ RandomNumber 1 10 ]
            set date [ gettimestamp ]
            if { $ora_compatible eq "true" } {
                set result [pg_exec $lda "exec delivery($w_id,$carrier_id,TO_TIMESTAMP($date,'YYYYMMDDHH24MISS'))" ]
            } else {
                if { $pg_storedprocs eq "true" } {
                    set result [pg_exec $lda "call delivery($w_id,$carrier_id,TO_TIMESTAMP('$date','YYYYMMDDHH24MISS')::timestamp without time zone)" ]
                } else {
                    set result [ pg_exec_prepared $lda delivery {} {} $w_id $carrier_id ]
                }
            }
            if {[pg_result $result -status] ni {"PGRES_TUPLES_OK" "PGRES_COMMAND_OK"}} {
                if { $RAISEERROR } {
                    error "[pg_result $result -error]"
                } else {
                    puts "Delivery Procedure Error set RAISEERROR for Details"
                }
                pg_result $result -clear
            } else {
                pg_result $result -clear
            }
        }
        #STOCK LEVEL
        proc slev { lda w_id stock_level_d_id RAISEERROR ora_compatible pg_storedprocs } {
            set threshold [ RandomNumber 10 20 ]
            if { $ora_compatible eq "true" } {
                set result [pg_exec $lda "exec slev($w_id,$stock_level_d_id,$threshold)" ]
            } else {
                if { $pg_storedprocs eq "true" } {
                    set result [pg_exec $lda "call slev($w_id,$stock_level_d_id,$threshold,0)"]
                } else {
                    set result [ pg_exec_prepared $lda slev {} {} $w_id $stock_level_d_id $threshold ]
                }
            }
            if {[pg_result $result -status] ni {"PGRES_TUPLES_OK" "PGRES_COMMAND_OK"}} {
                if { $RAISEERROR } {
                    error "[pg_result $result -error]"
                } else {
                    puts "Stock Level Procedure Error set RAISEERROR for Details"
                }
                pg_result $result -clear
            } else {
                pg_result $result -clear
            }
        }

        proc fn_prep_statement { lda } {
            set prep_neword "prepare neword (INTEGER, INTEGER, INTEGER, INTEGER, INTEGER) as select neword(\$1,\$2,\$3,\$4,\$5,0)"
            set prep_payment "prepare payment (INTEGER, INTEGER, INTEGER, INTEGER, INTEGER, INTEGER, NUMERIC, VARCHAR) AS select payment(\$1,\$2,\$3,\$4,\$5,\$6,\$7,'\$8','0',0)"
            set prep_ostat "prepare ostat (INTEGER, INTEGER, INTEGER, INTEGER, VARCHAR) AS select * from ostat(\$1,\$2,\$3,\$4,'\$5') as (ol_i_id INTEGER,  ol_supply_w_id INTEGER, ol_quantity SMALLINT, ol_amount NUMERIC, ol_delivery_d TIMESTAMP WITH TIME ZONE,  out_os_c_id INTEGER, out_os_c_last CHARACTER VARYING, os_c_first CHARACTER VARYING, os_c_middle CHARACTER VARYING, os_c_balance NUMERIC, os_o_id INTEGER, os_entdate TIMESTAMP, os_o_carrier_id INTEGER)"
            set prep_delivery "prepare delivery (INTEGER, INTEGER) AS select delivery(\$1,\$2)"
            set prep_slev "prepare slev (INTEGER, INTEGER, INTEGER) AS select slev(\$1,\$2,\$3)"
            foreach prep_statement [ list $prep_neword $prep_payment $prep_ostat $prep_delivery $prep_slev ] {
                set result [ pg_exec $lda $prep_statement ]
                if {[pg_result $result -status] ni {"PGRES_TUPLES_OK" "PGRES_COMMAND_OK"}} {
                    error "[pg_result $result -error]"
                } else {
                    pg_result $result -clear
                }
            }
        }
        #RUN TPC-C
        set lda [ ConnectToPostgres $host $port $sslmode $user $password $db ]
        if { $lda eq "Failed" } {
            error "error, the database connection to $host could not be established"
        } else {
            if { $ora_compatible eq "true" } {
                set result [ pg_exec $lda "exec dbms_output.disable" ]
                pg_result $result -clear
            } elseif { $pg_storedprocs eq "true" } {
                ;
            } else {
                fn_prep_statement $lda
            }
        }
        pg_select $lda "select max(w_id) from warehouse" w_id_input_arr {
            set w_id_input $w_id_input_arr(max)
        }
        #2.4.1.1 set warehouse_id stays constant for a given terminal
        set w_id  [ RandomNumber 1 $w_id_input ]  
        pg_select $lda "select max(d_id) from district" d_id_input_arr {
            set d_id_input $d_id_input_arr(max)
        }
        set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
        puts "Processing $total_iterations transactions with output suppressed..."
        set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
        for {set it 0} {$it < $total_iterations} {incr it} {
            if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
            set choice [ RandomNumber 1 23 ]
            if {$choice <= 10} {
                if { $KEYANDTHINK } { keytime 18 }
                neword $lda $w_id $w_id_input $RAISEERROR $ora_compatible $pg_storedprocs
                if { $KEYANDTHINK } { thinktime 12 }
            } elseif {$choice <= 20} {
                if { $KEYANDTHINK } { keytime 3 }
                payment $lda $w_id $w_id_input $RAISEERROR $ora_compatible $pg_storedprocs
                if { $KEYANDTHINK } { thinktime 12 }
            } elseif {$choice <= 21} {
                if { $KEYANDTHINK } { keytime 2 }
                delivery $lda $w_id $RAISEERROR $ora_compatible $pg_storedprocs
                if { $KEYANDTHINK } { thinktime 10 }
            } elseif {$choice <= 22} {
                if { $KEYANDTHINK } { keytime 2 }
                slev $lda $w_id $stock_level_d_id $RAISEERROR $ora_compatible $pg_storedprocs
                if { $KEYANDTHINK } { thinktime 5 }
            } elseif {$choice <= 23} {
                if { $KEYANDTHINK } { keytime 2 }
                ostat $lda $w_id $RAISEERROR $ora_compatible $pg_storedprocs
                if { $KEYANDTHINK } { thinktime 5 }
            }
        }
        pg_disconnect $lda
    }
}

