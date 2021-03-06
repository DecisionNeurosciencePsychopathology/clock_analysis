#!/usr/bin/env bash
set -e
#dynamically generate subject list based on MR data directory
datadir=/Volumes/Serena/MMClock/MR_Raw
find $datadir -type d -maxdepth 1 -mindepth 1 | xargs basename | tr '_' '\t' > sublist_id_date

#hard code header
hdr="lunaid age adult female scandate" # wverb_iq wperf_iq wfull4 wfull2 bdiTotal sssTAS sssES sssDIS sssB sssTOT asrTInternal asrTExternal asrTTotalProb"

echo $hdr | tr " " "\t" > subinfo_db

while read lunaid scandate; do

    #echo -ne "$lunaid	$age	$scandate	$rest	"
    #mysql -h lncddb --user=lncd --password=B@ngal0re lunadb_nightly -BNe "
    #mysql -h arnold.wpic.upmc.edu --user=lncd --password=B@ngal0re lncddb3 -BNe "
    mysql -h arnold.wpic.upmc.edu --user=lncd --password=B@ngal0re lunadb_nightly -BNe "
select
  info.lunaid,
  TIMESTAMPDIFF(HOUR,info.DateOfBirth,lg.VisitDate)/8766.0 AS age,
  TIMESTAMPDIFF(HOUR,info.DateOfBirth,lg.VisitDate)/8766.0 > 18.0 AS adult,
  case sexid when 1 then '0' when 2 then '1' else '?' end as female,
  date_format(lg.VisitDate,'%Y-%m-%d') as scandate
from tSubjectInfo as info
left join tVisitLog as lg
   on lg.lunaid=info.lunaid
where info.lunaid = '$lunaid'
  and date_format(lg.VisitDate,'%Y%m%d') = '$scandate'
order by lg.visitdate
limit 1
;
" 
echo
done < sublist_id_date | sed 's///g;/^$/d' >> subinfo_db

# select
#   info.lunaid,
#   TIMESTAMPDIFF(HOUR,info.DateOfBirth,$scandate)/8766.0 AS AgeYearsDecimal,
#   case sexid when 1 then '0' when 2 then '1' else '?' end as female
# from tSubjectInfo as info
# where info.lunaid = '$lunaid'
# limit 1;



#proper query, but several visits missing
# select
#   info.lunaid,
#   TIMESTAMPDIFF(HOUR,info.DateOfBirth,lg.VisitDate)/8766.0 AS AgeYearsDecimal,
#   case sexid when 1 then '0' when 2 then '1' else '?' end as female,
#   date_format(lg.VisitDate,'%Y-%m-%d') as scandate
# from tSubjectInfo as info
# left join tVisitLog as lg
#    on lg.lunaid=info.lunaid
# where info.lunaid = '$lunaid'
#   and date_format(lg.VisitDate,'%Y%m%d') = '$scandate'
# order by lg.visitdate
# limit 1;



#  | sed  's///g;/^$/d' >> icaSubjInfo_DB.txt

#  dupps.*
#left join dupps
#   on lg.lunaid=dupps.lunaid
# order by  abs( datediff(dupps.visitdate,lg.visitdate) )


#   dwasi.wverb_iq, dwasi.wperf_iq, dwasi.wfull4, dwasi.wfull2,
#   dBDI.bdiTotal,
#   dss.sssTAS, dss.sssES, dss.sssDIS, dss.sssBS, dss.sssTOT,
#   dasr.asrTInternal, dasr.asrTExternal, dasr.asrTTotalProb

# left join dSensationSeeking as dss
#    on dss.lunaID = lg.lunaID
# left join dwasi
#    on dwasi.VisitID = dss.VisitID
# left join dbdi
#    on dbdi.VisitID = dss.VisitID
# left join dasr
#    on dasr.VisitID = dss.VisitID
#order by abs( datediff(dss.visitdate,lg.visitdate) )

#  case sexid when 1 then 'male' when 2 then 'female' else '?' end as sex,
