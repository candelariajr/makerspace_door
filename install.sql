drop database makerspaceentry;
create database if not exists makerspaceentry;
use makerspaceentry;
create table if not exists allowed_entry(
	id int not null auto_increment primary key,
    bid int(9) not null unique,
    active_state char(1) not null default '1',
    manual_add char(1) not null default '0',
    added_date datetime not null default current_timestamp
);

create table if not exists vars(
	id int not null auto_increment primary key,
    variable_name varchar(64) not null unique,
    variable_value varchar(128) not null,
    variable_description varchar(512)
);

insert into vars (variable_name, variable_value, variable_description) values
('software_version', '1.0', 'Current Software Version'),
('last_import', '2020-01-01 00:00:01', 'DateTime of Last Import from ASULearn'),
('last_external_sync', '2020-01-01 00:00:01', 'DateTime of Last Sync with Sharepoint'); 

create table if not exists foreign_import(
	id int not null auto_increment primary key,
    bid int (9) not null,
    manual_add char(1) default '0',
    manual_remove char(1) default '0'
);

# This is the ASULearn import function. It is ONLY for a string of BIDs
# Acceptible Formats:
# "#########"
# "#########, #########, ... #########"
# Trailing commas and spaces are BAD, but will be trimmed in case of logic
# screwups. 
# Other than that, there is no protection (from rejection of the argument). 
# Do not put letters, code, etc, as it will be flagged and kicked out
delimiter //
create procedure import_array(bid_array varchar(4096))
modifies sql data
begin
	# The return string is constantly overwritten as it acts as a 
    # error/rejection reason or a marker as to when the proc was 
    # stopped

	# declare before set
    # configuration variables
    declare strLen int;
    # operation variables
	declare returnString varchar(64);
    declare failureCondition int(1);
    
    #configuration values
    set strLen = 9;
    #operation values
    set failureCondition = 1;
    set returnString = "Failure on Startup";
    
    # trimming spaces and commas as protection measures against logic errors
    # passed from Node.js process
    set bid_array = trim(' ' from bid_array);
    set bid_array = trim(',' from bid_array);
    
    # We can't run string length computations on null
    if bid_array is null then
        set failureCondition = 1;
        set returnString = "Null given as proc argument";
	 	# set bid_array = "";
	end if;
    
    # Evaluate length of argument for validity
	if length(bid_array) >= 9 then
		if length(bid_array) = strLen then
			set failureCondition = 0;
            set returnString = "Length of Argument OK: Single Entry"; 
		else
			# complex logic, just move along
			if mod((length(bid_array) - strLen), (strLen + 1)) != 0 then
				set failureCondition = 1;
                set returnString = "Length of Argument Wrong: Multiple Entries";
			else	
				set failureCondition = 0;
                set returnString = "Length of Argument OK: Multiple Entries";
			end if;
		end if;
	else
		set failureCondition = 1;
        set returnString = "Length of Argument Too Small";
	end if;
    
    #The rest of these statements will only happen if the argument structure appears to be valid
    if failureCondition = 0 then 
		start transaction;
			drop table if exists temp_array;
			create table temp_array(
				bid int(9)
			);
            set failureCondition = 1;
		commit;
        # This makes more sence if you think about it from a Db perspective
        # As part of the creation of the table, failureCondition must be changed. 
        # If the transaction breaks, the system reverts the database back to the
        # state before the transaction. 
        if failureCondition = 1 then
			set failureCondition = 0;
		else
			set returnString = "Transaction Failure: temp_array table can't be initialized";
        end if;
    end if;
    
    # test code...remove later. Procs have NO return type. 
    # They act like a select statement.
    # set returnString = cast('123456a9897' as signed);
    # returns: 123456
    # if the first char is a letter -> 0
    # returns an int of the first numbers, then exits when the first letter in encountered
    
    # MEAT AND POTATOES
    # Check if condition is OK, then chop up the string into ints, verify, then populate temp_array
    if failureCondition = 0 then
		#chop the array down to a series of ints and import
		reconcile_array: loop
			# the string has been chopped down to 0
			if length(bid_array) = 0 then
				leave reconcile_array;
            end if;
			if length(bid_array) = 9 then
				start transaction;
					insert into temp_array (bid) values
                    ('999999999');
				commit;
                leave reconcile_array;
            end if;
			leave reconcile_array;
		end loop;
	end if;
    
    if failureCondition = 0 then
		## set returnString = "Success";
        set failureCondition = 0;
    end if;    
    select failureCondition as 'Failure Condition', returnString as 'Status';
end; //
delimiter ;

delimiter //
create procedure remote_sync()
begin
end; //
delimiter ;


insert into allowed_entry (bid) values 
(900013663);

# select import_array("123456789");
call import_array('123456789');
# select * from allowed_entry;
