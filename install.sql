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

insert into allowed_entry (bid) values 
(900013663);
