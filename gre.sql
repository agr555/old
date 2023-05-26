with xmlstucture (N_Z,N_O,PROCESS_ID,execDate_Z,execDate_O,File_Z,File_O,Z,O)
as
(select mZ.ID as N_Z, mO.ID as N_O,mZ.PROCESS_ID,
mZ.EXECUTION_DATE as execDate_Z,mO.EXECUTION_DATE as execDate_O,
'C:\gre\mq_portal\'|| CAST(mZ.FILENAME as varchar(50)) as File_Z,
'C:\gre\mq_portal\'|| CAST(mO.FILENAME as varchar(50)) as File_O,
XMLCAST ( XMLPARSE (DOCUMENT CAST (mZ.data AS BLOB (5000k))PRESERVE WHITESPACE) as xml ) as Z
,XMLCAST ( XMLPARSE (DOCUMENT CAST (mO.data AS BLOB (5000k))PRESERVE WHITESPACE) as xml ) as O
from gre.J_MESSAGE mZ
 join gre.J_MESSAGE mO on mZ.PROCESS_ID = mO.PROCESS_ID
where mZ.FILENAME like '%FromUOgre_por%'  and mZ.DESCRIPTION='LIST_XXX' 
and mZ.EXECUTION_DATE >=? and mZ.EXECUTION_DATE <=?
and mO.FILENAME like '414%'
)
select *  from xmlstucture
,XMLTABLE ('$d/*:FromSubsystem/*:request/*:PayLoad/SyncRequest/*:MessageData/*:AppData/*:gre_por/*:events/*:event'  passing  xmlstucture.Z   as "d" 
   COLUMNS 
   authorityID     VARCHAR(120)    PATH '*:authority/@id',
   mobile    VARCHAR(1254)     PATH '*:mobile',receiveddate TIMESTAMP  PATH '*:received-date',
   service    VARCHAR(1254)     PATH '*:service',procedure1 VARCHAR(1254)     PATH '*:procedure',
   serviceID    VARCHAR(254)     PATH '*:service/@id',
   procedureID VARCHAR(254)     PATH '*:procedure/@id',
   okt    VARCHAR(254)     PATH '*:okt', 
   foreignID     VARCHAR(120)    PATH '@foreign-id'  
    )AS X
 ,XMLTABLE ('$e/*:FromSubsystem/*:response/*:PayLoad/*:Envelope/*:Body/*:Envelope/*:Body/SyncResponse/*:Message'  passing  xmlstucture.O   as "e" 
   COLUMNS 
    SmeStat    VARCHAR(20)     PATH '*:Status'   ,SmevDate TIMESTAMP  PATH '*:Date'
  )AS Y  ,
  (select jmp.value,rs.INTERN_SID,je.DATE,
jp.EXTERN_PROCESS, jm.ID, jm.PROCESS_ID

FROM gre.R_SR rs
INNER JOIN gre.J_PROCESS jp on jp.SERVICE_ID = rs.ID
INNER JOIN gre.J_MESSAGE jm on jm.PROCESS_ID = jp.ID
INNER JOIN gre.J_EVENTS je on je.MESSAGE_ID = jm.ID
left join gre.J_MESSAGE_param jmp on jmp.message_ID=jm.ID 
where je.DATE >? and je.DATE <?
and rs.INTERN_SID like 'gre_por001' and  jm.IS_OUT=1 and jmp.name='UUID' 
and  je.EVENT_TYPE_id=2 

order by jp.EXTERN_PROCESS,je.EVENT_TYPE_id) as zz
where zz.value=x.foreignID