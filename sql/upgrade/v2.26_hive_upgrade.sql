DROP TABLE IF EXISTS etl_day_view_depth_addr_apk_user;
create table etl_day_view_depth_addr_apk_user(
addr_code string,
addr_country_code string,
addr_country_name string,
addr_province_code string,
addr_province_name string,
addr_city_code string,
addr_city_name string,
addr_borough_code string,
addr_borough_name string,
addr_town_code string,
addr_town_name string,
apk_version string,
client_type int,
sp_id string,
visit_depth int,
visit_num int,
play_num int
)
PARTITIONED BY (day int)
STORED AS PARQUET;

DROP TABLE IF EXISTS etl_day_page_view_log;
CREATE TABLE IF NOT EXISTS etl_day_page_view_log(
user_id   string,
page_id   string,
view_times bigint,
stay_duration bigint,
page_first_day int,
first_visit_user string,
is_visit int,
client_type int,
apk_version string,
sp_id string,
addr_code string,
addr_country_code string,
addr_country_name string,
addr_province_code string,
addr_province_name string,
addr_city_code string,
addr_city_name string,
addr_borough_code string,
addr_borough_name string,
addr_town_code string,
addr_town_name string,
year_index int,
quater_index int,
month_index int,
week_index int
)
PARTITIONED BY (day int)
STORED AS PARQUET;

DROP TABLE IF EXISTS etl_hour_page_performance_log;
CREATE TABLE IF NOT EXISTS etl_hour_page_performance_log(
session_id string,
user_id string,
user_name string,
device_id string,
mac string,
ip string,
network_type int,
system_name int,
system_version string,
page_id string,
page_sid string,
client_type int,
apk_version string,
sp_id string,
addr_code string,
addr_country_code string,
addr_country_name string,
addr_province_code string,
addr_province_name string,
addr_city_code string,
addr_city_name string,
addr_borough_code string,
addr_borough_name string,
addr_town_code string,
addr_town_name string,
load_time string,
ready_duration bigint,
is_ready int,
loaded_duration bigint,
is_loaded int,
is_hotdate int
)
PARTITIONED BY (day int, minute string)
STORED AS PARQUET;

DROP TABLE IF EXISTS etl_day_page_performance_log;
CREATE TABLE IF NOT EXISTS etl_day_page_performance_log(
session_id string,
user_id string,
user_name string,
device_id string,
mac string,
ip string,
network_type int,
system_name int,
system_version string,
page_id string,
page_sid string,
client_type int,
apk_version string,
sp_id string,addr_code string,
addr_country_code string,
addr_country_name string,
addr_province_code string,
addr_province_name string,
addr_city_code string,
addr_city_name string,
addr_borough_code string,
addr_borough_name string,
addr_town_code string,
addr_town_name string,
load_time string,
ready_duration bigint,
is_ready int,
ready_user string,
loaded_duration bigint,
is_loaded int,
loaded_user string,
is_hotdate int,
hotdate_user string,
year_index int,
quater_index int,
month_index int,
week_index int
)
PARTITIONED BY (day int)
STORED AS PARQUET;

DROP TABLE IF EXISTS etl_day_page_block_view_log;
CREATE TABLE IF NOT EXISTS etl_day_page_block_view_log(
user_id string,
page_id string,
block_id string,
view_times bigint,
block_first_day int,
first_visit_user string,
is_visit int,
client_type int,
apk_version string,
sp_id string,
addr_code string,
addr_country_code string,
addr_country_name string,
addr_province_code string,
addr_province_name string,
addr_city_code string,
addr_city_name string,
addr_borough_code string,
addr_borough_name string,
addr_town_code string,
addr_town_name string,
year_index int,
quater_index int,
month_index int,
week_index int
)
PARTITIONED BY (day int)
STORED AS PARQUET;

DROP TABLE IF EXISTS etl_day_page_block_content_view_log;
CREATE TABLE IF NOT EXISTS etl_day_page_block_content_view_log(
user_id string,
page_id string,
block_id string,
block_content string,
view_times bigint,
content_first_day int,
first_visit_user string,
is_visit int,
client_type int,
apk_version string,
sp_id string,
addr_code string,
addr_country_code string,
addr_country_name string,
addr_province_code string,
addr_province_name string,
addr_city_code string,
addr_city_name string,
addr_borough_code string,
addr_borough_name string,
addr_town_code string,
addr_town_name string,
year_index int,
quater_index int,
month_index int,
week_index int
)
PARTITIONED BY (day int)
STORED AS PARQUET;

alter table etl_day_view_depth_addr_apk_user change visit_num visit_num bigint;
alter table etl_day_view_depth_addr_apk_user change play_num play_num bigint;
