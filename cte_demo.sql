drop schema if exists cte_demo cascade;
create schema cte_demo;

create table cte_demo.users (
  userid serial not null primary key,
  name text,
  email text
);
create table cte_demo.addresses (
  addressid serial not null primary key,
  userid integer,
  address text,
  city text,
  state text,
  zip text
);
create table cte_demo.user_history (
  historyid serial not null primary key,
  userid integer not null REFERENCES cte_demo.users(userid),
  addressid integer not null REFERENCES cte_demo.addresses(addressid),
  action text
);
