select * from bi_work.jj_app_lapse_predictions_v02 where eventtype = 'pageView' and pagetype = 'category' limit 100;
select * from bi_work.jj_app_lapse_predictions_Stage limit 100;
delete from bi_work.jj_app_lapse_predictions_stage where udid in ('(SELECT (CASE WHEN (6433=6433) THEN 6433 ELSE 6433*(SELECT 6433 FROM INFORMATION_SCHEMA.CHARACTER_SETS) END))','00000000-0000-0000-0000-000000000000');

truncate table bi_work.jj_app_lapse_predictions_v02;
insert into bi_work.jj_app_lapse_predictions_v02 
with t2 as (
select distinct evisitorid as udid,lastvisitdate,firstvisitdate
from reports.app_tenure_final
where firstvisitdate >= current_date - 56
)

, t1 as (
select * from bi_work.jj_app_lapse_predictions_Stage    
where (url in ('/offers/ourbest','/','/offers/justforyou','saved','http://www.retailmenot.com/ideas/hot-products','/favorites','/searchresults') or
url ilike '/nearby/malls%' or url ilike '/nearby/stores%' or url ilike '/nearby/food%' or url ilike '/mall/%' or url ilike '/categories%') and eventtype = 'pageView'
)

select distinct 
a.udid,lastvisitdate, firstvisitdate
,eventtype, date(created) - firstvisitdate as tenurenum
,case when url in ('/offers/ourbest','/') then 'coverflow' when url = '/favorites' then 'favorites' when url ilike '/nearby/malls%' then 'nearbymalls' when url ilike '/nearby/stores%' then 'nearbystores'
        when url ilike '/nearby/food%' then 'nearbyfood' when url ilike '/mall/%' then 'mall'
        when url = '/offers/justforyou' then 'jfy' when url = '/searchresults' then 'search' when url ilike '/categories%' then 'category' when url ilike '/store/%' then 'storepage' 
        when url = 'http://www.retailmenot.com/ideas/hot-products' then 'products' when url = '/saved/' then 'saved' when url ilike '/offer/%' then 'offerview' end as pagetype
,'all'::varchar(500) as contenttype
,count(b.udid)
from t2 a
left join t1 b on a.udid = b.udid and date(b.created) <= firstvisitdate + 28 and date(b.created) >= firstvisitdate
group by 1,2,3,4,5,6,7
;

insert into bi_work.jj_app_lapse_predictions_v02
with t2 as (
select distinct evisitorid as udid,lastvisitdate,firstvisitdate
from reports.app_tenure_final
where firstvisitdate >= current_date - 56
)

, t1 as (
select * from bi_work.jj_app_lapse_predictions_stage
where url ilike '/offer/%' or eventtype in ('coverFlow','coverflowImpression','outClick','offerTap')
)

select a.udid,lastvisitdate, firstvisitdate
,eventtype, date(b.created) - firstvisitdate as tenurenum
,case when url in ('/offers/ourbest','/') then 'coverflow' when url = '/favorites' then 'favorites' when url ilike '/nearby/malls%' then 'nearbymalls' when url ilike '/nearby/stores%' then 'nearbystores'
        when url ilike '/nearby/food%' then 'nearbyfood' when url ilike '/mall/%' then 'mall'
        when url = '/offers/justforyou' then 'jfy' when url = '/searchresults' then 'search' when url ilike '/categories%' then 'category' when url ilike '/store/%' then 'storepage' 
        when url = 'http://www.retailmenot.com/ideas/hot-products' then 'products' when url = '/saved/' then 'saved' when url ilike '/offer/%' then 'offerview' end as pagetype
,case when coupontype = 'printable' then 'in-store' when coupontype <> 'printable' and (description ilike '%in-store%' or description ilike '%instore%') then 'in-store' else 'online' end as contenttype 
,count(b.udid)
from t2 a
left join t1 b on a.udid = b.udid and date(b.created) <= firstvisitdate + 28 and date(b.created) >= firstvisitdate
left join rmn.coupon c on c.couponid = replace(replace(coupons,';1;',''),';','')
group by 1,2,3,4,5,6,7
;


insert into bi_work.jj_app_lapse_predictions_v02
with t2 as (
select distinct evisitorid as udid,lastvisitdate,firstvisitdate
from reports.app_tenure_final
where firstvisitdate >= current_date - 56
)

, t1 as (
select * from bi_work.jj_app_lapse_predictions_stage
where url ilike '/store/%'
)

select a.udid,lastvisitdate, firstvisitdate
,eventtype, date(b.created) - firstvisitdate as tenurenum
,case when url in ('/offers/ourbest','/') then 'coverflow' when url = '/favorites' then 'favorites' when url ilike '/nearby/malls%' then 'nearbymalls' when url ilike '/nearby/stores%' then 'nearbystores'
        when url ilike '/nearby/food%' then 'nearbyfood' when url ilike '/mall/%' then 'mall'
        when url = '/offers/justforyou' then 'jfy' when url = '/searchresults' then 'search' when url ilike '/categories%' then 'category' when url ilike '/store/%' then 'storepage' 
        when url = 'http://www.retailmenot.com/ideas/hot-products' then 'products' when url = '/saved/' then 'saved' when url ilike '/offer/%' then 'offerview' end as pagetype
,case when split_part(taxonomy,'::',1) in ('restaurant','food') then 'food' 
           when split_part(taxonomy,'::',1) in ('clothing','departmentstore','shoes','beauty') then 'clothing'
           when split_part(taxonomy,'::',1) is null then 'other' else 'other' end as contenttype 
,count(b.udid)
from t2 a
left join t1 b on a.udid = b.udid and date(b.created) <= firstvisitdate + 28 and date(b.created) >= firstvisitdate
left join rmn.site d on d.domain = split_part(split_part(b.url,'/store/',2),'/',1)
left join draft.mydomains_retailmenot_category e using(categoryid)
group by 1,2,3,4,5,6,7
;

insert into bi_work.jj_app_lapse_predictions_v02
select a.udid, lastvisitdate,firstvisitdate, 'marketing_push_open' as eventtype
, date(b.opentime) - firstvisitdate as tenurenum, case when d.couponid is not null then 'offerview' else 'category' end as pagetype
,case when split_part(taxonomy,'::',1) in ('restaurant','food') then 'food' 
           when split_part(taxonomy,'::',1) in ('clothing','departmentstore','shoes','beauty') then 'clothing'
           when split_part(taxonomy,'::',1) is null then 'other' else 'other' end as contenttype 
, count(b.udid)
from (select distinct udid, firstvisitdate, lastvisitdate from bi_work.jj_app_lapse_predictions_v02) a
left join bi_Work.jj_push_opens b on a.udid = b.udid and date(b.opentime) <= firstvisitdate + 28 and b.campaign not ilike '%welcome%' and date(b.opentime) >= firstvisitdate
left join bi_work.push_campaign_metadata c on b.campaign = c.campaign
left join rmn.coupon d on d.couponid = c.contentid
left join rmn.site e using(siteid)
left join draft.mydomains_retailmenot_category f using(categoryid)
group by 1,2,3,4,5,6,7;

insert into bi_work.jj_app_lapse_predictions_v02
select a.udid, lastvisitdate, firstvisitdate, 'geofence_push_open' as eventtype
, date(b.created) - firstvisitdate as tenurenum, 'mall' as pagetype
,'all' as contenttype 
, count(distinct session)
from (select distinct udid, firstvisitdate, lastvisitdate from bi_work.jj_app_lapse_predictions_v02) a
left join bi_work.geofence_launches_stage b on a.udid = b.udid and b.created <= firstvisitdate + 28 and date(b.created) >= firstvisitdate
group by 1,2,3,4,5,6,7; 

select 
case when lastvisitdate < '10/12/2015' - 29 then 'lapsed' else 'active' end as status,
count(distinct udid)
,count(distinct case when eventtype = 'marketing_push_open' and count > 0 then udid else null end) 
from bi_work.jj_app_lapse_predictions_v02 
group by 1
 limit 100;
 
select max(tenurenum) from bi_work.jj_app_lapse_predictions_v02; 





