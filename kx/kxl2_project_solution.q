// This is the solution file for the Fundamentals Capstone project in Kx L2.
// It contains the answers to the exercises outlined in the project description.
// Each section corresponds to a specific exercise number.
// Four functions omitted because I forgot to scrap them off before closing the tab :p


// 1.1
dbPath: getenv[`HOME],"/fundamentals_capstone_dbs";
system "l ", dbPath

// 1.3
tradeSym:select distinct option_id from trade
uniqueOpts: distinct tradeSym[`option_id]

// 1.4
refServiceHandle: hopen `:localhost:5457

// 1.5
optRef: refServiceHandle (`getOptionRef; uniqueOpts)

// 1.6
uniqueInsts: distinct optRef`inst_id
instRef: refServiceHandle (`getInstRef; uniqueInsts)

// 1.7
csvPath: getenv[`AX_WORKSPACE],"/FP.Data/message.csv";
messages: ("**"; enlist ",") 0: hsym `$csvPath

/ 2.1
update expiry:"D"$expiry from `optRef
optRef

/ 2.3
update broker_id:extractBrokerId each exch_message from `messages
messages

/ 3.1
lastDate: last date;
t: select from trade where date=lastDate;
n: select option_id,time,bid,ask from nbbo where date=lastDate;
tradeContext: aj[`option_id`time; t; n];

/ 3.3
badTrades: select from (classifyTrades tradeContext) where exQuality=0b;

/ 3.4
savePath: hsym `$getenv[`AX_WORKSPACE],"/badTrades.csv";
savePath 0: csv 0: badTrades;

/ 4.1
edge15: select edge:sum edge, qty:sum qty, numTrds:count i by 15 xbar time.minute from trade where date=last date;

/ 4.2
edgeQtyPerMinute:{[t] }

/ 4.4
top5EdgeTimes: returnN[`edge; `top; 5; edge15];

/ 4.5
bottom5QtyTimes: returnN[`qty; `bottom; 5; edge15];

/ 4.6
timeSeries: exec (edge; qty; numTrds) from edge15;
timeSeries: `edge`qty`numTrds ! timeSeries;

/ 4.7
edgeCor: {x cor timeSeries`edge} each timeSeries

/ 5.1
optProfile: select numTrds:count i, avgEdge:avg edge, minQty:min qty, maxQty:max qty by option_id from trade where date=last date;

/ 5.2
highEdgeTrades: select from trade where date=last date, edge > (avg; edge) fby option_id;
edgeProfile: select numTrds:count i, avgEdge:avg edge, minQty:min qty, maxQty:max qty by option_id from highEdgeTrades;

/ 5.3
edgeProfileFull: (edgeProfile lj 1!optRef) lj 1!instRef;