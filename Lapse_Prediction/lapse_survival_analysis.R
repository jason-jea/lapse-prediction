library(survival)
library(ggplot2)
library(plyr)
library(dplyr)
library(reshape2)
library(RODBC)
library(RJDBC)
library(RPostgreSQL)
library(tidyr)
library(lubridate)
library(rmarkdown)
library(scales)
source("lapse_survival_functions.R")

drv <- dbDriver("PostgreSQL")

redshift = dbConnect(drv,host = 'rsh-rpt-se1-dat-rdb-mem-prd.c2vtvr6b5gso.us-east-1.redshift.amazonaws.com', dbname = 'members',user = "rmn_jjea", password = "182493Superman.",port='5439')

lapse.data <-
dbGetQuery(redshift,
           "
select udid,lastvisitdate,firstvisitdate,pagetype, contenttype, firstvisitdate - date('2015-04-09') as starttime
     , lastvisitdate - date('2015-04-09') as endtime
     , max(case when eventtype = 'pageView' then count else null end) as pageviewcounts
     , max(case when eventtype = 'coverflowImpression' then count else null end) as coverflowimpressioncounts
     , max(case when eventtype = 'coverFlow' then count else null end) as coverflowcounts
     , max(case when eventtype = 'outClick' then count else null end) as outclickcounts
     , max(case when eventtype = 'offerTap' then count else null end) as offertapcounts
     , max(case when eventtype = 'marketing_push_open' then count else null end) as marketingpushcounts
     , max(case when eventtype = 'geofence_push_open' then count else null end) as geofencepushcounts
     from (

           with t1 as (
            select *, rank() over (order by random()) as rank from (
                 select distinct udid, lastvisitdate, firstvisitdate
                 from bi_work.jj_app_lapse_predictions
                where firstvisitdate <= '9/2/2015'
                 ) x
           )
           
           ,t2 as (
           select udid,lastvisitdate,firstvisitdate
           ,case when eventtype in ('coverflowImpression','coverFlow')then 'coverflow'  when eventtype = 'outClick' then null else pagetype end as pagetype
           ,eventtype
           , case when contenttype in ('restaurant','food') then 'food' 
           when contenttype in ('clothing','departmentstore','shoes','beauty') then 'clothing'
           when contenttype is null then null else 'other' end as contenttype
           , count
           from bi_work.jj_app_lapse_predictions 
           where ((eventtype = 'pageView' and pagetype is not null) or (eventtype in ('coverflowImpression','coverFlow','outClick','offerTap'))
           or eventtype in ('marketing_push_open','geofence_push_open')) or eventtype is null
           )
            
          select a.udid, a.lastvisitdate, a.firstvisitdate, pagetype, eventtype, contenttype, count
          from t1 a
          left join t2 b using(udid)
          where rank <= 100000
           ) x
     group by 1,2,3,4,5,6
           ;")
  
lapse.data <-
lapse.data %>%
  melt(c("udid","lastvisitdate","firstvisitdate","pagetype","contenttype","starttime","endtime")) %>%
  filter(!(variable == "pageviewcounts" & pagetype != "storepage" & !is.na(contenttype)))%>%
  filter(!(variable == "offertapcounts" & pagetype == "offerview")) %>%
  filter(!(variable == "offertapcounts" & pagetype == "favorites")) %>%
  filter(!(variable == "offertapcounts" & pagetype == "jfy")) %>%
  filter(!(variable == "offertapcounts" & pagetype == "products")) %>%
  unite(eventpagecontent,pagetype, variable, contenttype) %>%
  spread(eventpagecontent, value) 
  
lapse.data[is.na(lapse.data)] <- 0
lapse.data$totalactions <- rowSums(lapse.data[,6:length(lapse.data)])

lapse.data$lapsed = 1
lapse.data[lapse.data$lastvisitdate >= as.Date("2015-09-02"),]$lapsed <- 0
# lapse.data <-
#   lapse.data %>% mutate(intervalend = ifelse(lapsed==1,as.numeric(lastvisitdate-firstvisitdate) + 1,
#                                              as.numeric(as.Date("2015-10-01") - firstvisitdate) + 1))

lapse.data <-
  lapse.data %>% mutate(intervalend = ifelse(lapsed==1, as.numeric(lastvisitdate - firstvisitdate) + 29,
                                             as.numeric(as.Date("2015-10-01") -firstvisitdate) + 1))


lapse.cleandata <-
  cbind(filterGoodVariables(lapse.data[,c(6:(length(lapse.data) - 2))]),intervalend = lapse.data$intervalend, lapsed = lapse.data$lapsed)

lapse.cleandata[,1:(length(lapse.cleandata) - 3)] <- ifelse(lapse.cleandata[,1:(length(lapse.cleandata) - 3)] > 0 ,1 ,0)

#lapse.cleandata[,1:(length(lapse.cleandata) - 2)] <- colwise(as.factor)(lapse.cleandata[,1:(length(lapse.cleandata) - 2)])

survivalResponse <- Surv(lapse.cleandata$intervalend,
                        lapse.cleandata$lapsed
                        )

lapse.model1 <- coxph(survivalResponse ~.,
                      data = lapse.cleandata[,1:(length(lapse.cleandata) - 2)])
summary(lapse.model1)

lapse.survivalfit = survfit(lapse.model1)

data.frame(cbind(time = lapse.survivalfit[[2]], survivalrate = lapse.survivalfit[[6]])) %>%
ggplot(aes(x=time,y=survivalrate))+geom_line()

oneVarSurvData(lapse.model1, lapse.cleandata[,1:60], "coverflow_coverflowcounts_clothing", c(0,1,5,10)) %>% melt("time") %>% 
  ggplot(aes(x = time, y = value, colour = variable)) + geom_line()

compareVarSurvData(lapse.model1, lapse.cleandata[,1:59], c("nearby_pageviewcounts", "mall_pageviewcounts", "offerview_marketingpushcounts",
                                                           "storepage_pageviewcounts", "jfy_pageviewcounts",
                                                           "category_pageviewcounts", "coverflow_coverflowcounts"), 
                   1) %>% melt("time") %>% 
  ggplot(aes(x = time, y = value, colour = variable)) + geom_line(size = 1.2) + theme_bw() +
  scale_y_continuous(labels = percent, name = "Survival Probability") + scale_x_continuous(name = "Days after First Launch") +
  scale_colour_manual(name = "Number actions in first 28 days", values = c("#756bb1","#9ecae1"))


compareVarSurvData(lapse.model1, lapse.cleandata[,1:62], c("nearbyfood_pageviewcounts_NA", 
                                                           "nearbymalls_pageviewcounts_NA"), 
                   1) %>% melt("time") %>% 
  ggplot(aes(x = time, y = value, colour = variable)) + geom_line()

colwise(
function(x) {
  return(sum(ifelse(x> 0 ,1,0)))
})(lapse.cleandata[,1:21])





