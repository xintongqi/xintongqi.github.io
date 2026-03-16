/ This is the solution file for the Fundamentals Capstone project in KX L3.
/ It contains the answers to the exercises outlined in the project description.
/ Each section corresponds to a specific exercise number.

/ 1.1
/ need to run dbmaint.q before running this
renamecol[`:/home/jovyan/developer/workspace/__nouser__/adv_capstone/f1; `event; `lappId; `lapId]

/ 1.2
\l .

/ 1.3
{[eventTab;sensorTab]
    sensorTab:`time xasc sensorTab;
    
    rack:eventTab cross (select distinct sensorId from sensorTab);
    rack:`time xasc rack;

    windows:(rack`time;rack`endTime);
    
    result:delete date from wj[windows; `sensorId`time; rack;(sensorTab;(avg;`sensorValue))];
    result
    }

/ 1.4
eventTbl: select from event where date=2020.01.02
sensorTbl: select from sensor where date=2020.01.02
lap: .f1.createLapTable[eventTbl;sensorTbl]
.Q.dpft[`:/home/jovyan/developer/workspace/__nouser__/adv_capstone/f1;2020.01.02;`sensorId;`lap]

/ 1.5
.Q.chk[`:/home/jovyan/developer/workspace/__nouser__/adv_capstone/f1]


/ 2.1
raceDay: ("stjsfs"; enlist ",") 0: `:/home/jovyan/developer/workspace/__nouser__/adv_capstone/AdvancedCapstone.Data/raceDay.csv

/ 2.2
system["l ",getenv[`AX_WORKSPACE],"/f1" ]
lapTable: select from lap where date = 2020.01.02

/ 2.3 and 2.4
{[raceTab;lapTab;mysensor]
    / 2.4 Validate mysensor parameter before proceeding
    if[not mysensor in `temp`tyre`wind`all;
      :(string mysensor)," is not a valid option for mysensor - valid options include `temp`tyre`wind`all"
    ];
        
    / 2.3 use sensorMap and functional form
    sensorMap:`temp`tyre`wind`all!(
          enlist(like;`sensorId;"temp*");
          enlist(like;`sensorId;"tyre*");
          enlist(like;`sensorId;"wind*");
          enlist(1b)
    );
    sensorFilter:sensorMap mysensor;
    benchmark:?[lapTab;sensorFilter;(enlist`sensorId)!enlist`sensorId;(enlist`benchmarkValue)!enlist(avg;`sensorValue)];
    chk:?[raceTab;sensorFilter;(enlist`sensorId)!enlist`sensorId;`avgValue`stdDevValue!((avg;`sensorValue);(dev;`sensorValue))];
    
    / Below already exist in the original implementation 
    chk:update diffValue:"F"$.Q.f'[5;abs[benchmarkValue-avgValue]] 
        from benchmark lj chk;
    chk:update diffFlag:?[(diffValue>1);0b;1b],
               stdFlag:?[(stdDevValue>1.5);0b;1b]
        from chk;
    chk
    }

/ 2.5
/ First, change the order of filters in select statement in .viz.getModSensor
{[]
    symbols:`windSpeedFront`tempBackLeft`tyrePressureBackLeft;
    select from sensor where date in 2020.01.01 2020.01.02, sensorId in symbols, 0=lapId mod 2
    }
/ Then, apply a `p attribute on sensorId because we select heavily on this column in all three functions
{[d]
      data: select from sensor where date=d;
      data: `sensorId`time xasc data;
      data: update `p#sensorId from data;
      .[hsym`$"/home/jovyan/developer/workspace/__nouser__/adv_capstone/f1/",string[d],"/sensor/"; (); :; data]
  } each 2020.01.01 2020.01.02
/ Reload database
system["l ",getenv[`AX_WORKSPACE],"/f1" ]


/ 3.1
hdbH: hopen 5099

/ 3.2
.perm.users: ("s**"; enlist "\t") 0: `:/home/jovyan/developer/workspace/__nouser__/adv_capstone/AdvancedCapstone.Data/users.txt
.perm.users: update password:.Q.sha1 each password, api:`$api from .perm.users

/ 3.3
hdbH(set;`.perm.users;.perm.users)

/ 3.4
/ This function needs to be defined on the server side (can send through a handle)
.z.pw:{[u;p]
  stored: exec first password from .perm.users where user=u;
  $[stored ~ .Q.sha1 p;
      1b;
      '`access
  ]
  }

/ 3.5
hdbH ".perm.parseQuery:{[x]
      first parse x
      }"

/ 3.6
/ You need to load the database first on the server side
hdbH "\\l /home/jovyan/developer/workspace/__nouser__/adv_capstone/f1"
/ Then put this function on the server side (can send through a handle)
.z.pg:{[query]
  u: .z.u;
  api: exec first api from .perm.users where user=u;
  parsed: `$string .perm.parseQuery[query];
  $[api=`all;
      value query;
      parsed in api;
          value query;
      `notAuthorized
  ]
  }