
.qtb.cfg.testRoot:`.TEST;
.qtb.cfg.specials.beforeAll:`t_beforeAll;
.qtb.cfg.specials.afterAll:`t_afterAll;
.qtb.cfg.specials.beforeEach:`t_beforeEach;
.qtb.cfg.specials.afterEach:`t_afterEach;
.qtb.cfg.specials.overrides:`t_overrides;
.qtb.cfg.specials.mocks:`t_mocks;

.qtb.cfg.CmdlineParams:`run`verbose`debug`junit!(0b;0b;0b;`);

.qtb.STATE.callog:();
.qtb.STATE.currentOverrides:();

.qtb.countargs:{[func0]
  func1:$[-11h = type func0;get func0;func0];
  if[100h > typNum:type func1; :-1]; // not a function  
  if[101h = typNum;:$[func1 ~ enlist;0W;1]]; // 101h are unary "primitives" - except enlist, which takes any number of arguments
  if[102h = typNum;:2]; // operators take two arguments
  if[103h = typNum;'"iterators are unsupported"];
  
  // a composition has the valence of the second element
  if[105h = typNum;:.z.s value[func1] 1];

  if[not typNum in 100 104h;'"unsupported type"];
  
  // now this can only either be a lambda or a projection
  mfp:value func1;
  if[4h = type first mfp; :count mfp 1]; // a simple function
  
  // this is a projection. Computing the number of arguments of a projection:
  // (num args of base function) less number of arguments provided in the projection
  :(.z.s first mfp) - sum not (::) ~/: 1 _ mfp;
  };

.qtb.callogWrap:{[logname;tgtFunc]
  // arbitrary name for the function parameters
  argVars:";" sv enlist each (numargs:.qtb.countargs tgtFunc)#.Q.a; // example: "a;b;c..."
  // key step for wrapping tgtFunc within another lambda - without using a parameter...
  embeddedFunc:"-9!0x",raze string -8!tgtFunc;
  lognameS:$[10h = abs type logname;logname;string logname];
  // build the wrapping function as a string and then parse it back into a lambda
  :value "{[",argVars,"] args:(",argVars,"); .qtb.logCall[`$\"",lognameS,"\";args]; :value enlist[",embeddedFunc,"],",$[1 >= numargs;"enlist ";""],"args; }";
  };

.qtb.mock:{[id;newValue] `.qtb.STATE.currentOverrides set .qtb.STATE.currentOverrides upsert enlist .qtb.priv.mock[id;newValue]};
  
.qtb.override:{[varName;newValue] `.qtb.STATE.currentOverrides set .qtb.STATE.currentOverrides upsert enlist .qtb.priv.override[varName;newValue]};

.qtb.resetCallog:{[] `.qtb.STATE.callog set enlist `funcname`args!(`;::)};

.qtb.logCall:{[funcname;args] `.qtb.STATE.callog upsert (funcname;args); };

.qtb.getCallog:{[] 1 _ .qtb.STATE.callog };

// helper functions for writing tests
.qtb.assert.str:{[o] :(`s#(-0W 0 10 11h!(string;-3!;(::);-3!)))[type o] o};
.qtb.assert.assertfunc:{[checkf;cfname;expv;actv]
  if[checkf[expv;actv];:(::)];
  '$[10h <> type cfname;cfname[expv;actv];"Expected '",.qtb.assert.str[expv],"' ",cfname," '",.qtb.assert.str[actv],"'"];
  };

.qtb.assert.wrapassert:{[cf;cfname;args]
  .qtb.assert.assertfunc . $[2 = count args;(cf;cfname);enlist[cfg]],args;
 };

.qtb.assert.matches:.qtb.assert.assertfunc[~;"to match"];
.qtb.assert.equals:.qtb.assert.assertfunc[=;"to equal"];
.qtb.assert.within:.qtb.assert.assertfunc[within;"to be within"];
.qtb.assert.like:.qtb.assert.assertfunc[like;"to match the pattern"];
.qtb.assert.throws:{[expr;errpat]
  r:@[(1b;)eval@;expr;(0b;)];
  if[first r;'.qtb.assert.str[expr]," did not throw any exception"];
  if[not last[r] like errpat;'.qtb.assert.str[expr]," did not throw exception '",errpat,"', but '",last[r],"'"];
  };

.qtb.assert.callog:{[exp_log0]
  exp_log1:$[99h = type exp_log0;enlist exp_log0;exp_log0];
  if[not exp_log1 ~ .qtb.getCallog[];'"The actual call log does not match the expected one."];
  };

.qtb.assert.callogEmpty:{[]
  if[0 <> count .qtb.getCallog[];'"The call log is not empty."];
  };

.qtb.listDiff:{[a;b]
  n:min count each (a;b);
  if[n < count a;
    0N!"b is missing ",(string n - count a)," entries";
    :n _ a];
  if[n < count b;
    0N!"a is missing ",(string n - count b)," entries";
    :n _ b];
  mismatchIndices:where not a ~' b;
  :(a mismatchIndices;b mismatchIndices);
  };

/////

.qtb.priv.key:key;
.qtb.priv.get:get;

.qtb.priv.mock:{[id;newval0]
  newval1:$[isvalue:100h > type newval0;newval0;.qtb.callogWrap[id;newval0]];
  if[any isvalue,() ~ .qtb.priv.key id; :.qtb.priv.override[id;newval1]];

  origType:type origValue:.qtb.priv.get id;
  newType:type newval0;
  if[all (100h > origType;100h <= newType); '"cannot replace a value with a lambda"];
  if[(<>) . .qtb.countargs each (origValue;newval0);'"argument count mismatch"];
  :.qtb.priv.override[id;newval1];
  };


.qtb.priv.collectSpecials:{[paths;special] raze {x where not x~\:(::)} .qtb.cfg.testRoot ./: paths,\:special };

.qtb.priv.getSuite:{[path] $[any path ~/: (`;();`$();::);get .qtb.cfg.testRoot;.qtb.cfg.testRoot . path]};
  
.qtb.priv.genDict:enlist[`]!enlist (::);

.qtb.priv.Expungable:`.z.exit`.z.pc`.z.po`.z.ps`.z.pg`.z.ts`.z.wo`.z.wc`.z.vs`.z.ac`.z.bm`.z.zd`.z.ph`.z.pm`.z.pp`.z.pi`.z.pw;

.qtb.priv.execute:{[verbose;path0]
  path1:$[any path0 ~/: (();::;`); `$(); -11h = type path0;` vs path0;11h = type path0;path0;'"Invalid test path"];
  allSubpaths:til[count path1]#\: path1;
  if[not all 1b,.qtb.priv.executeSpecial[path1;.qtb.cfg.specials.beforeAll] each .qtb.priv.collectSpecials[allSubpaths;.qtb.cfg.specials.beforeAll];
    :.qtb.priv.failedSuiteRecords[verbose;`errorBeforeAll;path1]];
  beforeEaches:.qtb.priv.collectSpecials[allSubpaths;.qtb.cfg.specials.beforeEach];
  afterEaches:.qtb.priv.collectSpecials[allSubpaths;.qtb.cfg.specials.afterEach];
  overrides:.qtb.priv.collectSpecials[allSubpaths;.qtb.cfg.specials.overrides];
  mocks:.qtb.priv.collectSpecials[allSubpaths;.qtb.cfg.specials.mocks];
  suite:.qtb.priv.getSuite path1;
  // if the path refers to a single test we just run the test
  res:$[99h = type suite; .qtb.priv.executeSuite[verbose;beforeEaches;afterEaches;overrides;mocks;path1];
                          .qtb.priv.executeTest[verbose;beforeEaches;afterEaches;overrides;mocks;path1]];
  if[not all 1b,.qtb.priv.executeSpecial[path1;.qtb.cfg.specials.afterAll] each reverse .qtb.priv.collectSpecials[allSubpaths;.qtb.cfg.specials.afterAll];
    :.qtb.priv.failedSuiteRecords[verbose;`errorAfterAll;path1]];
  :res;
  };

.qtb.priv.tryThunk:{[th] 
  if[system "e"; :(1b;th[])];
  :@[{[th] (1b;th[])};th;(0b;)];
  }

.qtb.priv.executeSuite:{[verbose;beforeEaches0;afterEaches0;overrides;mocks;path]
  startTime:.z.p;
  res:.qtb.priv.runSuite[verbose;beforeEaches0;afterEaches0;overrides;mocks;path];
  :$[any res ~/: `errorBeforeAll`errorAfterAll;
    .qtb.priv.failedSuiteRecords[verbose;res;path];
    `suitename`start`time`tests!(path;startTime;.qtb.priv.durationSeconds[startTime;.z.p];res)];
  };

.qtb.priv.null2list:{$[(::) ~ x;();x]};

.qtb.priv.runSuite:{[verbose;beforeEaches0;afterEaches0;overrides0;mocks0;path]
  suite:.qtb.priv.getSuite path;
  
  beforeEaches1:beforeEaches0,.qtb.priv.null2list suite .qtb.cfg.specials.beforeEach;
  afterEaches1:afterEaches0,  .qtb.priv.null2list suite .qtb.cfg.specials.afterEach;
  overrides1:overrides0,      .qtb.priv.null2list suite .qtb.cfg.specials.overrides;
  mocks1:mocks0,              .qtb.priv.null2list suite .qtb.cfg.specials.mocks;

  nodes:.qtb.priv.getNodes suite;
  tests:nodes 0;  subSuites:nodes 1;
  if[not .qtb.priv.executeSpecial[path;.qtb.cfg.specials.beforeAll;suite .qtb.cfg.specials.beforeAll]; :`errorBeforeAll];
  testResults:(::),.qtb.priv.executeTest[verbose;beforeEaches1;afterEaches1;overrides1;mocks1] each path,/:tests;
  suiteResults:testResults,.qtb.priv.executeSuite[verbose;beforeEaches1;afterEaches1;overrides1;mocks1] each path,/:subSuites;
  if[not .qtb.priv.executeSpecial[path;.qtb.cfg.specials.afterAll;suite .qtb.cfg.specials.afterAll];  :`errorAfterAll];
  :1 _ suiteResults;
  };

// split the suite into tests and subsuites
.qtb.priv.getNodes:{[suite]
  allNodes:(`,value .qtb.cfg.specials) _ suite; // grab a dict of all nodes that are not specials
  :{(where not x;where x)} 99h = type each allNodes;
  };

.qtb.priv.failedTestRecord:{[result;test] `testname`result`time!(test;result;0f) };

.qtb.priv.failedSuiteRecords:{[verbose;result;path]
  nodes:.qtb.priv.getNodes .qtb.priv.getSuite path;
  tests:nodes 0; subSuites:nodes 1;
  if[result ~ `errorBeforeAll; .qtb.priv.reportResult[verbose;result] each path,/:tests];
  testResults:(::),.qtb.priv.failedTestRecord[result] each path,/:tests;
  suiteResults:testResults,.z.s[verbose;result] each path,/:subSuites;
  :`suitename`start`time`tests!(path;.z.p;0f;1 _ suiteResults);
  };

.qtb.priv.executeTest:{[verbose;beforeEaches;afterEaches;overrides;mocks;path]
  `.qtb.STATE.currentOverrides set .qtb.priv.apply2pairlist[.qtb.priv.override;overrides],.qtb.priv.apply2pairlist[.qtb.priv.mock;mocks];
  startTime:.z.p;
  res:.qtb.priv.runTest[beforeEaches;afterEaches;path];
  .qtb.priv.revertOverrides .qtb.STATE.currentOverrides;
  `.qtb.STATE.currentOverrides set ();
  .qtb.priv.reportResult[verbose;res;path];
  :`testname`result`time!(path;res;.qtb.priv.durationSeconds[startTime;.z.p]);
  };

.qtb.priv.runTest:{[beforeEaches;afterEaches;path]
  testFunc:.qtb.priv.getSuite path;
  if[1 <> .qtb.countargs testFunc;:`invalid];
  if[not all 1b,.qtb.priv.executeSpecial[path;.qtb.cfg.specials.beforeEach] each beforeEaches;:`errorBeforeEach];
  .qtb.resetCallog[];
  res:first .qtb.priv.tryThunk testFunc;
  if[not all 1b,.qtb.priv.executeSpecial[path;.qtb.cfg.specials.afterEach] each reverse afterEaches;:`errorAfterEach];
  :`failure`success res;
  };

.qtb.priv.executeSpecial:{[testPath;specialType;specialFunc]
  if[any specialFunc ~/: (::;();{}); :1b];  // 'in' does not work for ()
  res:.qtb.priv.tryThunk specialFunc;
  if[not first res;.qtb.priv.println ("." sv string testPath,specialType)," threw exception: ",res 1];
  :first res;
  };

.qtb.priv.println:-1;
.qtb.priv.print:1;

.qtb.priv.override:{[varName;newValue]
  currValue:`varname`defined`origValue!varName,@[{(1b;get x)};varName;(0b;::)];
  varName set newValue;
  :currValue;
  };

.qtb.priv.apply2pairlist:{[func;pairlist] func ./: pairlist };

.qtb.priv.dropVariable:{[varname] {![` sv -1 _ x;();0b;(),last x]} {$[1 = count x;``;()],x} ` vs varname };

.qtb.priv.restore:{[overRec]
  $[overRec`defined;                           (set) . overRec`varname`origValue;
    overRec[`varname] in .qtb.priv.Expungable; system "x ",string overRec`varname;
                                               .qtb.priv.dropVariable overRec`varname];
  };

.qtb.priv.revertOverrides:{[overrides] .qtb.priv.restore each reverse (),overrides; };

.qtb.priv.durationSeconds:{[start;end] (end - start) % 0D00:00:01 };

.qtb.priv.resultMapVerbose:`success`failure`errorBeforeAll`errorBeforeEach`errorAfterAll`errorAfterEach!("succeded";"failed";"setup error";"setup error";"teardown error";"teardown error");
.qtb.priv.resultMap:`success`failure`errorBeforeAll`errorBeforeEach`errorAfterAll`errorAfterEach!".FEEEE";
.qtb.priv.reportResult:{[verbose;res;path]
  .qtb.priv.print $[verbose;
    raze ("." sv string path;" ";.qtb.priv.resultMapVerbose res;"\n");
    .qtb.priv.resultMap res];
  };

.qtb.priv.resultTree2Table:{[testResultTree]
  if[`suitename in key testResultTree; :raze .z.s each testResultTree`tests];
  if[`testname in key testResultTree;  :enlist @[testResultTree;`testname;` sv]];
  '"qtb: unknown test result value: ",-3!testResultTree;
  };

.qtb.priv.resultTree2JunitXml:{[indentLvl;testResultTree]
  pf:indentLvl#" ";
  pf2:"  ",pf;
  if[`testname in key testResultTree;
    bd:pf,"<testcase name=\"",("." sv string testResultTree`testname),"\" classname=\"\" time=\"",trim[.Q.fmt[10;3;testResultTree`time]],"\"";
    if[`success ~ testResultTree`result;:enlist bd," />"];
    if[`failure ~ testResultTree`result;:(bd,">";pf2,"<failure type=\"failed\"/>";pf,"</testcase>")];
    :(bd,">";pf2,"<error type=\"error\"/>";pf,"</testcase>");
  ];
  if[not `suitename in key testResultTree;'"qtb: invalid result value"];
  tests:where `testname in/: key each testResultTree`tests;
  o:();
  if[0 < count tests;
    alltests:testResultTree[`tests;tests];
    h:pf,"<testsuite name=\"",("." sv string testResultTree`suitename),"\" ";
    h,:"package=\"\" hostname=\"",string[.z.h],"\" ";
    h,:"errors=\"",string[count select from alltests where not result in `success`failure],"\" ";
    h,:"failures=\"",string[count select from alltests where result=`failure],"\" ";
    h,:"tests=\"",string[count alltests],"\" ";
    h,:"timestamp=\"",(-4 _ @[;10;:;"T"] @[;4 7;:;"-"] string 15h$testResultTree`start),"\" ";
    h,:"time=\"",trim[.Q.fmt[10;3;testResultTree`time]],"\">";
    b:raze .z.s[2 + indentLvl]'[alltests];
    da:pf2,/:("<properties />";"<system-out />";"<system-err />");
    o:(h;da 0),b,1 _ da;
    o,:enlist pf,"</testsuite>";
  ];
  :o,raze .z.s[indentLvl] each testResultTree[`tests] where not `testname in/: key each testResultTree`tests;
  };

.qtb.priv.junitXmlDoc:{[testResultTree] :("<?xml version=\"1.0\" encoding=\"UTF-8\"?>";"<testsuites>"),.qtb.priv.resultTree2JunitXml[2;testResultTree],enlist"</testsuites>"; };

.qtb.priv.writeTextFile:{x 0: y};

.qtb.priv.show:show;

.qtb.priv.reportResults:{[junitfile;testResultTree]
  if[not null junitfile; .qtb.priv.writeTextFile[hsym junitfile;.qtb.priv.junitXmlDoc testResultTree]];
  rt:`path xcol .qtb.priv.resultTree2Table testResultTree;
  if[count fails:select from rt where result <> `success; .qtb.priv.show fails];
  :rt;
  };

.qtb.priv.scriptWithArgs:{[] all (not null .z.f;0 < count .z.x)};

.qtb.priv.system:system;

.qtb.priv.parseCmdline:{[zx]
  firstOptFlagIdx:count[zx] ^ first where "-" = first each zx;
  options:.Q.opt firstOptFlagIdx _ zx;
  positionals:(firstOptFlagIdx # zx),raze 1 _/: options where 1 < count each options;
  params:.Q.def[.qtb.cfg.CmdlineParams;first each options];
  if[1 > count positionals;'"Missing target script argument(s)."];
  :(positionals;@[params;`debug;or[0 <> .qtb.priv.system "e"]]);
  };

.qtb.priv.exit:{exit not x};

// TODO: accept paths in `.a.b.c notation?
.qtb.priv.runTests:{[debug;verbose;junit;path]
  e_orig:string .qtb.priv.system "e";
  .qtb.priv.system "e ","01" debug;
  testresults:.qtb.priv.execute[verbose;path];
  .qtb.priv.system "e ",e_orig;
  if[not verbose;.qtb.priv.println ""];
  :.qtb.priv.reportResults[junit;testresults];
  };

.qtb.exec:.qtb.priv.runTests[0b;0b;`];
.qtb.debug:.qtb.priv.runTests[1b;0b;`];


///////////////////////////////
// run with command-line paramaters
// in debug mode, exit only if there is success
// in non-debug mode, always exit, set status from exception or test result
.qtb.run:{[]
  if[not .qtb.priv.scriptWithArgs[];:(::)];
  args:.qtb.priv.parseCmdline .z.x;
  .qtb.priv.system each "l ",/: first args;
  if[not args[1;`run];:(::)];
  runfunc:{(1b;.qtb.priv.runTests . (x`debug`verbose`junit),enlist `$())};
  r:$[args[1;`debug];runfunc;@[runfunc;;(0b;)]] args 1;
  if[not r 0;.qtb.priv.println "Caught exception: ",r 1];
  success:$[not r 0;0b;0 = count select from r[1] where result<>`success];
  if[not args[1;`debug];.qtb.priv.exit success];
  };


@[.qtb.run;::;{.qtb.priv.println "Exception from .qtb.run: ",x; if[not system "e";exit 1];}];
