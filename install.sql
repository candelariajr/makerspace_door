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
# Trailing commas and spaces are BAD, but will be trimmed. 
# Other than that, there is no protection. 
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
			set failureCondition = 1;
			drop table if exists temp_array;
			create table temp_array(
				bid int(9)
			);
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
    
    
    reconcile_array: loop
		leave reconcile_array;
    end loop;
    
    
    if failureCondition = 0 then
		## set returnString = "Success";
        set failureCondition = 0;
    end if;    
    select returnString as 'Status', failureCondition as 'Failure Condition';
end; //
delimiter ;



insert into allowed_entry (bid) values 
(900013663);

# select import_array("123456789");
call import_array('123456789,123654987,654123987,');
# select * from allowed_entry;
