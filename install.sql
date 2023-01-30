create database if not exists makerspaceentry;
use makerspaceentry;
create table if not exists allowed_entry(
    id int not null auto_increment primary key,
    bid int(9) not null unique,
    active_state char(1) not null default '1',
    manual_add char(1) not null default '0',
    manual_remove char(1) not null default '0',
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

# function stub
delimiter //
create function import(in bid_array varchar(4096))
begin
    ## test cpde for counting delimiters
    set @test_string = '123,456,789,4654,78978';
    ## select(@test_string);
    
    ## find out number of occurances of the delimiter
    set @delimiter_count = round(length(@test_string) - length(replace(@test_string, ',', "")));
    select(@delimiter_count);


    declare strLen int 9;
    if bid_array is null then
        set bid_array = '';
    end if;
    
    drop table if exists temp_array;
    create table temp_array(
        bid varchar(9)
    );
    
    ## loop syntax
    process:
	loop
	end loop process;
    
end;
end delimiter //


insert into allowed_entry (bid) values 
(900013663);
