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

delimiter //
create procedure import_array(bid_array varchar(4096))
modifies sql data
begin
	# declare before set
    declare strLen int;
	declare returnString varchar(32);
    declare failureCondition int(1);
    
    set strLen = 9;
    set failureCondition = 1;
    set returnString = "Failure on Startup";
    
    if bid_array is null then
	 	set bid_array = '';
	end if;
    
    if length(bid_array) = strLen then
	 	set returnString = "TEST 2";
	end if;
    
    start transaction;
		drop table if exists temp_array;
		create table temp_array(
			bid varchar(9)
		);
		insert into temp_array(bid) values
		('444444444');
        set returnString = "temp_array created";		
	commit;
    
    reconcile_array: loop
		set failureCondition = 0;
		leave reconcile_array;
    end loop;
    
    
    if failureCondition = 0 then
		set returnString = "Success";
    end if;    
    select returnString as 'Status', failureCondition as 'Failure Condition';
end; //
delimiter ;



insert into allowed_entry (bid) values 
(900013663);

# select import_array("123456789");
call import_array("123456789");
# select * from allowed_entry;
