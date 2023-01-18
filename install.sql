create database if not exists makerspaceentry;
use makerspaceentry;
create table if not exists allowed_entry(
	id int not null auto_increment primary key,
    bid int(9) not null unique,
    active_state char(1) not null default '1',
    added_date datetime not null default current_timestamp
);

insert into allowed_entry (bid) values
(900013663);