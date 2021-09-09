// Helper functions
.tst.logCall:{[fn;args] `.tst.CALLOG upsert `funcname`args!(fn;args); };

.tst.resetCallog:{[] `.tst.CALLOG set enlist `funcname`args!(`;::); };

.tst.getCallog:{[] 1 _ .tst.CALLOG };

.tst.execTest:{[tst]
  r:@[(1b;)tst@;::;(0b;)];
  :`test`success`error!(tst;r 0;$[r 0;::;r 1]);
  };

.tst.loadScript:{[] system "l ",TESTTARGET; };

.tst.run:{[]
  .tst.loadScript[];
  :.tst.execTest each {x where x like "test_*"} key `.;
  };

.tst.p.catch1:{[func;arg] @[(1b;) func @;arg;(0b;)]};
.tst.p.catchN:{[func;args] @[(1b;) func .;args;(0b;)]};
.tst.p.checkEx:{[cf;func;arg;excpt]
  r:cf[func;arg];
  if[r 0;'"no exception thrown"];
  if[not excpt ~ r 1;'"Expected '",excpt,"' error, but got '",r[1],"'"];
  };

.tst.checkEx1:.tst.p.checkEx[.tst.p.catch1];
.tst.checkExN:.tst.p.checkEx[.tst.p.catchN];

.tst.override:{[varname;newval]
  r:`name`defined`origValue!(varname;not () ~ key varname;@[get;varname;::]);
  varname set newval;
  :r;
  };

.tst.applyOverrides:{.qtb.priv.apply2pairlist[.qtb.priv.override;x]};

.tst.alltests:{[]
  -1 "Running all tests";
  failed:exec test from .tst.run[] where not success;
  if[0 < count failed;-1 "Failed tests: `","`" vs string failed];
  if[0 = count failed;-1 "All tests succeeded."];
  :0 = count failed;
  };

assert:{[expval;actval] if[not expval ~ actval;'"assert: Mismatch between expected '",(-3!expval),"' and actual '",(-3!actval),"'"]; };

//-------------------

TESTTARGET:"qtb2.q"

// test the override functions first so we can use them too
test_override:{[]
  `testOverride set 42;
  assert[42;get `testOverride];
  .tst.checkEx1[get;`testUndefined;"testUndefined"];
  .tst.checkEx1[get;`.z.pw;".z.pw"];
  overrides:.tst.applyOverrides ((`testOverride;100);(`testUndefined;42);(`.z.pw;{}));
  assert[([] varname:`testOverride`testUndefined`.z.pw; defined:100b; origValue:(42;::;::)); overrides];
  assert[100;get `testOverride];
  assert[42;get `testUndefined];
  assert[{};get `.z.pw];
  .qtb.priv.revertOverrides overrides;
  assert[42;get `testOverride];
  .tst.checkEx1[get;`testUndefined;"testUndefined"];
  .tst.checkEx1[get;`.z.pw;".z.pw"];  
  };

test_callogWrap:{[]
  assert[{[a] args:(a); .qtb.logCall[`$"f";args]; :value enlist[-9!0x010000001700000064000a00070000007b5b5d2060617d],enlist args; };      .qtb.callogWrap[`f;{[] `a}]];
  assert[{[a] args:(a); .qtb.logCall[`$"f";args]; :value enlist[-9!0x010000001a00000064000a000a0000007b656e6c69737420787d],enlist args; };.qtb.callogWrap[`f;{enlist x}]];
  assert[{[a;b;c] args:(a;b;c); .qtb.logCall[`$"f";args]; :value enlist[-9!0x010000001900000064000a00090000007b28793b783b7a297d],args; }; .qtb.callogWrap[`f;{(y;x;z)}]];
  assert[{[a] args:(a); .qtb.logCall[`$"f";args]; :value enlist[-9!0x010000001a00000064000a000a0000007b656e6c69737420787d],enlist args; };.qtb.callogWrap["f";{enlist x}]];
  };


// .qtb.countargs
test_countargs:{[]
  // No argument function"
  assert[1;.qtb.countargs {[]}];;
  // One argument function
  assert[1;.qtb.countargs {[a] a+1}];;
  // Three argument function
  assert[3;.qtb.countargs {[a;b;c] a+b+c}]
  // -- projections
  // Two arg func with first provided
  assert[1;.qtb.countargs {[a;b] a+b}[1]];
  // Two arg func with second provided
  assert[1;.qtb.countargs {[a;b] a+b}[;1]];
  // Five arg func with arg two and four given
  assert[3;.qtb.countargs {[a;b;c;d;e] a+b+c+d+e}[;2;;3]];
  // Four arg func with first one given
  assert[3;.qtb.countargs {[a;b;c;d] a+b+c+d}[1]];
  // Four arg func with last one given
  assert[3;.qtb.countargs {[a;b;c;d] a+b+c+d}[;;1]];
  // Four arg func with second one given
  assert[3;.qtb.countargs {[a;b;c;d] a+b+c+d}[;1]];
  // not a function
  assert[-1;.qtb.countargs 42];
  // primitives
  assert[1;.qtb.countargs (::)];
  assert[1;.qtb.countargs neg];
  // enlist
  assert[0W;.qtb.countargs enlist];
  // operator
  assert[2;.qtb.countargs (,)];
  assert[2;.qtb.countargs (-)];
  // compositions
  assert[1;.qtb.countargs system];
  assert[2;.qtb.countargs ('[{2*x};{x+y}])];
  assert[2;.qtb.countargs ('[{2*x};{x+y+z}[;1;]])];
  };

// .qtb.override - simple, no unit test

// .qtb.resetCallog, .qtb.logCall, .qtb.getCallog
test_callLogging:{[]
  .qtb.resetCallog[];
  assert[enlist `funcname`args!(`;::);.qtb.STATE.callog];  
  .qtb.logCall[`noarg;(::)];
  .qtb.logCall[`onearg;`asym];
  .qtb.logCall[`someargs;(42;`somesym;"yes")];
  .qtb.logCall[`onearg;([] c:1 2)];
  .qtb.logCall[`onearg;`a`b!2 1];
  expFuncallLog:([] funcname:`noarg`onearg`someargs`onearg`onearg; args: ((::);`asym;(42;`somesym;"yes");([] c:1 2);`a`b!2 1));
  assert[expFuncallLog;.qtb.getCallog[]];
  };

// .qtb.assert.str
test_assert_str:{[]
  `V set `u#`x`y;
  ev:`V$`y`x`x`y;
  data:([] v:(0Ng;1b;`x;42f;(`x;42);"lolo";`a`b;.z.d;ev 0;til 3;ev 0 1);
    estr:("00000000-0000-0000-0000-000000000000";(),"1";(),"x";"42";"(`x;42)";"lolo";"`a`b";string .z.d;(),"y";"0 1 2";"`V$`y`x"));
  {assert[x`estr;.qtb.assert.str x`v]} each data;
  };

// .qtb.assertfunc, .qtb.assert.wrapassert, .qtb.assert.matches, .qtb.assert.equals, .qtb.assert.throws
test_asserts:{[]
  assert[(::);.qtb.assert.wrapassert[{[x;y] 1b};"checkfunc";1 2]];
  .tst.checkExN[.qtb.assert.wrapassert;({[x;y] 0b};"checkfunc";1 2);"Expected '1' checkfunc '2'"];
  .tst.checkExN[.qtb.assert.wrapassert;({[x;y] 0b};{[x;y] "foo"};1 2);"foo"];
  assert[(::);.qtb.assert.throws[({[x] '"boom!"};42);"boom!"]];
  .tst.checkExN[.qtb.assert.throws;({[x] 42};"catch me!");"{[x] 42} did not throw any exception"];
  
  assert[(::);.qtb.assert.matches[1;1]];
  .tst.checkExN[.qtb.assert.matches;1 2;"Expected '1' to match '2'"];

  assert[(::);.qtb.assert.equals[2i;2]];
  .tst.checkExN[.qtb.assert.equals;1 2;;"Expected '1' to be equal to '2'"];

  assert[(::);.qtb.assert.within[7;5 10]];
  .tst.checkExN[.qtb.assert.within;(1;5 10);"Expected '1' to be within '5 10'"];
  
  assert[(::);.qtb.assert.like[`xx;"xx"]];
  .tst.checkExN[.qtb.assert.like;(`xx;"ab");"Expected 'xx' to match the pattern 'ab'"];
  };

test_mock:{[]
  qtb_priv_override:.qtb.priv.override; qtb_callogWrap:.qtb.callogWrap; qtb_countargs:.qtb.countargs;
  `.qtb.priv.override set {.tst.logCall[`override;(x;y)]; (x;y)};
  `.qtb.callogWrap set {.tst.logCall[`callogWrap;(x;y)]; 42};
  `.qtb.countargs set {.tst.logCall[`countargs;x]; 2};
  `.qtb.priv.key set {.tst.logCall[`key;x]; x};
  `.qtb.priv.get set {.tst.logCall[`get;x]; {(y;x)}};

  .tst.resetCallog[];
  assert[(`myfunc;42);.qtb.priv.mock[`myfunc;{(x;y)}]];
  exp_callog1:([]
    funcname:`callogWrap`key`get`countargs`countargs`override;
    args:((`myfunc;{(x;y)});`myfunc;`myfunc;{(y;x)};{(x;y)};(`myfunc;42))
    );
  assert[exp_callog1;.tst.getCallog[]];

  .tst.resetCallog[];
  assert[(`myval;10);.qtb.priv.mock[`myval;10]];
  exp_log2:([] funcname:`key`override; args:(`myval;(`myval;10)));
  assert[exp_log2;.tst.getCallog[]];
  
  .tst.resetCallog[];
  `.qtb.countargs set {.tst.logCall[`countargs;x]; $[x ~ {(y;x)};2;1]};
  .tst.checkExN[.qtb.priv.mock;(`myfunc;{(x;y)});"argument count mismatch"];
  assert[-1 _ exp_callog1;.tst.getCallog[]];

  .tst.resetCallog[];
  `.qtb.priv.get set {.tst.logCall[`get;x]; "hi!"};
  .tst.checkExN[.qtb.priv.mock;(`myfunc;{(x;y)});"cannot replace a value with a lambda"];

  .tst.resetCallog[];
  `.qtb.priv.key set {.tst.logCall[`key;x]; ()};
  assert[(`myfunc;"hi!");.qtb.priv.mock[`myfunc;"hi!"]];
  exp_callog2:([] funcname:`key`override; args:(`myfunc;(`myfunc;"hi!")));
  assert[exp_callog2;.tst.getCallog[]];

  `.qtb.priv.override set qtb_priv_override;
  `.qtb.callogWrap set qtb_callogWrap;
  `.qtb.countargs set qtb_countargs;
  `.qtb.priv.key set key;
  `.qtb.priv.get set get;
  `.q.value set value;
  };


flush_tests:{[] {![`.TEST;();0b;(),x]} each  key[.qtb.cfg.testRoot] except `;};

test_collectSpecials:{[]
  specials:({[] `beforeAll1; };{[] `beforeAll2; };{[] `beforeAll3; });
  ovr:.tst.applyOverrides (
    ((` sv .qtb.cfg.testRoot,.qtb.cfg.specials.beforeAll);specials 0);
    ((` sv .qtb.cfg.testRoot,(`suite;.qtb.cfg.specials.beforeAll));specials 1);
    ((` sv .qtb.cfg.testRoot,(`suite;`subsuite;.qtb.cfg.specials.beforeAll));specials 2));
  
  assert[specials;.qtb.priv.collectSpecials[(`$();(),`suite;`suite`subsuite);.qtb.cfg.specials.beforeAll]];
  assert[1 _ specials;.qtb.priv.collectSpecials[((),`suite;`suite`subsuite);.qtb.cfg.specials.beforeAll]];
  assert[2 _ specials;.qtb.priv.collectSpecials[enlist `suite`subsuite;.qtb.cfg.specials.beforeAll]];
  assert[();.qtb.priv.collectSpecials[(`$();(),`suite;`suite`subsuite);.qtb.cfg.specials.afterAll]];

  .qtb.priv.revertOverrides over; flush_tests[];
  };

test_getSuite:{[]
  ovr:.tst.applyOverrides enlist (` sv .qtb.cfg.testRoot,`suite`subsuite`mytest;{[] });
  
  exp_res:``suite!(::;``subsuite!(::;``mytest!(::;{[] })));
  assert[exp_res;.qtb.priv.getSuite `$()];
  assert[exp_res[`suite;`subsuite];.qtb.priv.getSuite `suite`subsuite];
  
  .qtb.priv.revertOverrides ovr; flush_tests[];
  };


test_execute:{[]
  dummySpecials:({[] 1};{[] 2});
  ovrr:.tst.applyOverrides (
    (`.test.state.executeSpecialCallCount;0);
    (`.qtb.priv.executeSpecial;{.tst.logCall[`executeSpecial;(x;y;z)]; 1b});
    (`.qtb.priv.collectSpecials;{.tst.logCall[`collectSpecials;(y;z)]; x}[dummySpecials]);
    (`.qtb.priv.failedSuiteRecords;{.tst.logCall[`failedSuiteRecords;(x;y;z)]; `failedRecords});
    (`.qtb.priv.getSuite;{.tst.logCall[`getSuite;enlist x];``a`b!(::;{[] `a;};{[] `b;})});
    (`.qtb.priv.executeSuite;{[a;b;c;d;e;f] .tst.logCall[`executeSuite;(a;b;c;d;e;f)]; `suiteResult});
    (`.qtb.priv.executeTest;{[a;b;c;d;e;f] .tst.logCall[`executeTest;(a;b;c;d;e;f)]; `testResult})
    );

  // no errors, full suite
  .tst.resetCallog[];
  assert[`suiteResult;.qtb.priv.execute[1b;`a`b`c]];
  allsubpaths:(`$();(),`a;`a`b);
  exp_log1:([]
    funcname:`collectSpecials`executeSpecial`executeSpecial`collectSpecials`collectSpecials`collectSpecials`collectSpecials`getSuite`executeSuite`collectSpecials`executeSpecial`executeSpecial;
    args:((allsubpaths;.qtb.cfg.specials.beforeAll);
      (`a`b`c;.qtb.cfg.specials.beforeAll;dummySpecials 0);
      (`a`b`c;.qtb.cfg.specials.beforeAll;dummySpecials 1);
      (allsubpaths;.qtb.cfg.specials.beforeEach);
      (allsubpaths;.qtb.cfg.specials.afterEach);
      (allsubpaths;.qtb.cfg.specials.overrides);
      (allsubpaths;.qtb.cfg.specials.mocks);
      enlist `a`b`c;
      (1b;dummySpecials;dummySpecials;dummySpecials;dummySpecials;`a`b`c);
      (allsubpaths;.qtb.cfg.specials.afterAll);
      (`a`b`c;.qtb.cfg.specials.afterAll;dummySpecials 1);
      (`a`b`c;.qtb.cfg.specials.afterAll;dummySpecials 0)
      ));
  assert[exp_log1;.tst.getCallog[]];

  // no errors, single test
  .tst.resetCallog[];
  `.qtb.priv.getSuite set {.tst.logCall[`getSuite;enlist x]; {[] `b;}};
  assert[`testResult;.qtb.priv.execute[1b;`a`b`c]];
  exp_log2:.[exp_log1;(8;`funcname);:;`executeTest];
  assert[exp_log2;.tst.getCallog[]];

    // no errors, single test (dotted notation)
  .tst.resetCallog[];
  assert[`testResult;.qtb.priv.execute[1b;`a.b.c]];
  assert[exp_log2;.tst.getCallog[]];

  // afterAll failure
  .tst.resetCallog[];
  `.qtb.priv.executeSpecial set {.tst.logCall[`executeSpecial;(x;y;z)]; `.test.state.executeSpecialCallCount set mod[.test.state.executeSpecialCallCount + 1;4]; not 3 = .test.state.executeSpecialCallCount};
  assert[`failedRecords;.qtb.priv.execute[1b;`a`b`c]];
  exp_log3:exp_log2 upsert `funcname`args!(`failedSuiteRecords;(1b;`errorAfterAll;`a`b`c));
  assert[exp_log3;.tst.getCallog[]];

  // beforeAll failure
  .tst.resetCallog[];
  `.qtb.priv.executeSpecial set {.tst.logCall[`executeSpecial;(x;y;z)]; `.test.state.executeSpecialCallCount set mod[.test.state.executeSpecialCallCount + 1;4]; not 1 = .test.state.executeSpecialCallCount};
  assert[`failedRecords;.qtb.priv.execute[1b;`a`b`c]];
  exp_log4:.[exp_log3 0 1 2 12;(3;`args;1);:;`errorBeforeAll];
  assert[exp_log4;.tst.getCallog[]];

  // path normalizations
  .tst.resetCallog[];
  `.qtb.priv.executeSpecial set {.tst.logCall[`executeSpecial;(x;y;z)]; 0b};
  assert[`failedRecords;.qtb.priv.execute[1b;()]];
  exp_log5:([]
    funcname:`collectSpecials`executeSpecial`executeSpecial`failedSuiteRecords;
    args:((();.qtb.cfg.specials.beforeAll);
      (`$();.qtb.cfg.specials.beforeAll;dummySpecials 0);
      (`$();.qtb.cfg.specials.beforeAll;dummySpecials 1);
      (1b;`errorBeforeAll;`$())));
  assert[exp_log5;.tst.getCallog[]];

  // check of error path
  .tst.checkExN[.qtb.priv.execute;(1b;`a`b!1 2);"Invalid test path"];
    
  .qtb.priv.revertOverrides ovrr;
  };

test_tryThunk:{[]
  ce:system "e";
  system "e 0";
  assert[(1b;42);.qtb.priv.tryThunk {[] 42}];
  assert[(0b;"hey!");.qtb.priv.tryThunk {[] '"hey!"}];
  system "e 1";
  assert[(1b;42);.qtb.priv.tryThunk {[] 42}];
  .tst.checkEx1[.qtb.priv.tryThunk;{[] '"hey!"};"hey!"];
  system "e ",string ce;
  };

test_executeSuite:{[]
  ovrr:.tst.applyOverrides (
    (`.qtb.priv.runSuite;{[a;b;c;d;e;f] .tst.logCall[`runSuite;(a;b;c;d;e;f)] `testResult});
    (`.qtb.priv.failedSuiteRecords;{.tst.logCall[`failedSuiteRecords;(x;y;z)];`failedSuiteRecResult});
    (`.qtb.priv.durationSeconds;{[x;y] .tst.logCall[`durationSeconds;0N]; 42f}));

  // normal run, no errors
  .tst.resetCallog[];
  exp_res:`suitename`time`tests!(`pa`th;42f;`testResult);
  assert[exp_res;`start _ .qtb.priv.executeSuite[1b;`beforeEaches;`afterEaches;`overrides;`mocks;`pa`th]];
  exp_log1:([] funcname:`runSuite`durationSeconds;  args:((1b;`beforeEaches;`afterEaches;`overrides;`mocks;`pa`th);0N));
  assert[exp_log1;.tst.getCallog[]];

  // errorAfterAll
  .tst.resetCallog[];
  `.qtb.priv.runSuite set {[a;b;c;d;e;f] .tst.logCall[`runSuite;(a;b;c;d;e;f)] `errorAfterAll};
  assert[`failedSuiteRecResult;.qtb.priv.executeSuite[1b;`beforeEaches;`afterEaches;`overrides;`mocks;`pa`th]];
  exp_log2:([] funcname:`runSuite`failedSuiteRecords;  args:((1b;`beforeEaches;`afterEaches;`overrides;`mocks;`pa`th);(1b;`errorAfterAll;`pa`th)));
  assert[exp_log2;.tst.getCallog[]];
  
  .qtb.priv.revertOverrides ovrr;
  };

test_runSuite:{[]
  testSuite1:(``test`suite!(::;{[] .tst.logCall[`test;::];};`aSuite)),(value[` _ .qtb.cfg.specials]!{{[x;y] (`special;x)}[x]} each key ` _ .qtb.cfg.specials),.qtb.cfg.specials[`overrides`mocks]!(((`a;42);(`b;2021.04.10));enlist (`func;{[] '"hey!"}));
  ovrr:.tst.applyOverrides (
    (`.qtb.priv.getSuite;{.tst.logCall[`getSuite;y]; x}[testSuite1]);
    (`.qtb.priv.getNodes;{.tst.logCall[`getNodes;x]; (`t1`t2;`s1`s2)});
    (`.qtb.priv.executeSpecial;{.tst.logCall[`executeSpecial;(x;y;z)]; 1b});
    (`.qtb.priv.executeTest;{[a;b;c;d;e;f] .tst.logCall[`executeTest;(a;b;c;d;e;f)]; `testResult});
    (`.qtb.priv.executeSuite;{[a;b;c;d;e;f] .tst.logCall[`executeSuite;(a;b;c;d;e;f)]; `suiteResult}));

  // normal run
  .tst.resetCallog[];
  exp_res1:`testResult`testResult`suiteResult`suiteResult;
  assert[exp_res1;.qtb.priv.runSuite[0b;(),`beforeEaches;(),`afterEaches;enlist (`override;100);enlist (`mock;{});`pa`th]];
  exp_beforeEaches1:(`beforeEaches;{[x;y] (`special;x)}[`beforeEach]);
  exp_afterEaches1:(`afterEaches;{[x;y] (`special;x)}[`afterEach]);
  exp_overrides1:((`override;100);(`a;42);(`b;2021.04.10));
  exp_mocks1:((`mock;{});(`func;{[] '"hey!"}));
  exp_log1:([]
    funcname:`getSuite`getNodes`executeSpecial`executeTest`executeTest`executeSuite`executeSuite`executeSpecial;
    args:(`pa`th;
      testSuite1;
      (`pa`th;.qtb.cfg.specials.beforeAll;{[x;y] (`special;x)}[`beforeAll]);
      (0b;exp_beforeEaches1;exp_afterEaches1;exp_overrides1;exp_mocks1;`pa`th`t1);
      (0b;exp_beforeEaches1;exp_afterEaches1;exp_overrides1;exp_mocks1;`pa`th`t2);
      (0b;exp_beforeEaches1;exp_afterEaches1;exp_overrides1;exp_mocks1;`pa`th`s1);
      (0b;exp_beforeEaches1;exp_afterEaches1;exp_overrides1;exp_mocks1;`pa`th`s2);      
      (`pa`th;.qtb.cfg.specials.afterAll;{[x;y] (`special;x)}[`afterAll])));
  assert[exp_log1;.tst.getCallog[]];

  // no specials
  testSuite2:value[` _ .qtb.cfg.specials] _ testSuite1;
  .tst.resetCallog[];
  `.qtb.priv.getSuite set {.tst.logCall[`getSuite;y]; x}[testSuite2];
  exp_beforeEaches2:(),`beforeEaches;
  exp_afterEaches2:(),`afterEaches;
  exp_overrides2:enlist (`override;100);
  exp_mocks2:enlist (`func;{[] '"hey!"});
  assert[exp_res1;.qtb.priv.runSuite[0b;exp_beforeEaches2;exp_afterEaches2;exp_overrides2;exp_mocks2;`pa`th]]
  exp_log2:([]
    funcname:`getSuite`getNodes`executeSpecial`executeTest`executeTest`executeSuite`executeSuite`executeSpecial;
    args:(`pa`th;
      testSuite2;
      (`pa`th;.qtb.cfg.specials.beforeAll;::);
      (0b;exp_beforeEaches2;exp_afterEaches2;exp_overrides2;exp_mocks2;`pa`th`t1);
      (0b;exp_beforeEaches2;exp_afterEaches2;exp_overrides2;exp_mocks2;`pa`th`t2);
      (0b;exp_beforeEaches2;exp_afterEaches2;exp_overrides2;exp_mocks2;`pa`th`s1);
      (0b;exp_beforeEaches2;exp_afterEaches2;exp_overrides2;exp_mocks2;`pa`th`s2);      
      (`pa`th;.qtb.cfg.specials.afterAll;::)));
  assert[exp_log2;.tst.getCallog[]];

  // afterAll error
  `.qtb.priv.executeSpecial set {.tst.logCall[`executeSpecial;(x;y;z)]; not .qtb.cfg.specials.afterAll ~ y};
  `.qtb.priv.getSuite set {.tst.logCall[`getSuite;y]; x}[testSuite1];
  .tst.resetCallog[];
  assert[`errorAfterAll;.qtb.priv.runSuite[0b;(),`beforeEaches;(),`afterEaches;enlist (`override;100);();`pa`th]];
  exp_log3:update @[;4;:;enlist (`func;{[] '"hey!"})] each args from exp_log1  where funcname in `executeTest`executeSuite;
  assert[exp_log3;.tst.getCallog[]];

  // beforeAll error
  `.qtb.priv.executeSpecial set {.tst.logCall[`executeSpecial;(x;y;z)]; not .qtb.cfg.specials.beforeAll ~ y};
  .tst.resetCallog[];
  assert[`errorBeforeAll;.qtb.priv.runSuite[0b;(),`beforeEaches;(),`afterEaches;enlist (`override;100);();`pa`th]];
  assert[3#exp_log1;.tst.getCallog[]];
    
  .qtb.priv.revertOverrides ovrr;  
  };

test_getNodes:{[]
  assert[(({[] `t1};{[] `t2});42 43 44);.qtb.priv.getNodes .qtb.cfg.specials,`test1`suite1`test2`suite2`suite3!({[] `t1};42;{[] `t2};43;44);];
  };

test_failedSuiteRecords:{[]
  ovrr:.tst.applyOverrides (
    (`.qtb.priv.getSuite;{.tst.logCall[`getSuite;x]; $[x ~ `pa`th;`asuite;`subsuite]});
    (`.qtb.priv.getNodes;{.tst.logCall[`getNodes;x]; $[x ~ `asuite;(`t1`t2;`s1`s2);((),`t1;())]});
    (`.qtb.priv.reportResult;{.tst.logCall[`reportResult;(x;y;z)]}));

  .tst.resetCallog[];
  exp_tstres1:([] testname:(`pa`th`t1;`pa`th`t2); result:`errorBeforeAll`errorBeforeAll; time:0 0f);
  exp_tstres2:enlist `testname`result`time!(`pa`th`s1`t1;`errorBeforeAll;0f);
  exp_steres:([] suitename:(`pa`th`s1;`pa`th`s2); time:0 0f; tests:(exp_tstres2;.[exp_tstres2;(0;`testname;2);:;`s2]));
  exp_res1:`suitename`time`tests!(`pa`th;0f;1 _ (enlist[(::)],exp_tstres1),exp_steres);

  res0:.qtb.priv.failedSuiteRecords[1b;`errorBeforeAll;`pa`th];
  res1:{[o] $[`tests in key o;@[`start _ o;`tests;:;.z.s each o`tests];o] } res0; // remove the timestamps
  assert[exp_res1;res1];
  exp_log1:([] funcname:`getSuite`getNodes`reportResult`reportResult`getSuite`getNodes`reportResult`getSuite`getNodes`reportResult;
    args:(`pa`th;`asuite;(1b;`errorBeforeAll;`pa`th`t1);(1b;`errorBeforeAll;`pa`th`t2);`pa`th`s1;`subsuite;(1b;`errorBeforeAll;`pa`th`s1`t1);`pa`th`s2;`subsuite;(1b;`errorBeforeAll;`pa`th`s2`t1)));
  assert[exp_log1;.tst.getCallog[]];
  
  .qtb.priv.revertOverrides ovrr;
  };


test_executeTest:{[]
  ovrr:.tst.applyOverrides (
    (`.qtb.STATE.currentOverrides;());
    (`.qtb.priv.runTest;{.tst.logCall[`runTest;(x;y;z)]; (a;b;42)});
    (`.qtb.priv.reportResult;{.tst.logCall[`reportResult;(x;y;z)];});
    (`.qtb.priv.durationSeconds;{[x;y] .tst.logCall[`durationSeconds;0N 0N]; 100f}));
  // no overrides for .tst.applyOverrides and ..revertOverrides as we are using them...

  .tst.resetCallog[];
  exp_res1:`testname`result`time!(`my`test;(42;`xx`yy;42);100f);
  assert[();key `a];
  assert[();key `b];
  assert[exp_res1;.qtb.priv.executeTest[1b;`beforeEaches;`afterEaches;((`a;42);(`b;`xx`yy));enlist (`mockme;{[] '"mockmock"});`my`test]];
  exp_log1:([]
    funcname:`runTest`reportResult`durationSeconds;
    args:((`beforeEaches;`afterEaches;`my`test);(1b;exp_res1`result;`my`test);0N 0N));
  assert[exp_log1;.tst.getCallog[]];
  assert[();key `a];
  assert[();key `b];
  assert[();.qtb.STATE.currentOverrides];

  .qtb.priv.revertOverrides ovrr;
  };

test_runTest:{[]
  ovrr:.tst.applyOverrides (
    (`.qtb.priv.getSuite;{.tst.logCall[`getSuite;x]; {[]}});
    (`.qtb.countargs;{.tst.logCall[`countargs;x] 1});
    (`.qtb.priv.executeSpecial;{.tst.logCall[`executeSpecial;(x;y;z)]; 1b});
    (`.qtb.resetCallog;{.tst.logCall[`resetCallog;::];});
    (`.qtb.priv.tryThunk;{.tst.logCall[`tryThunk;x]; enlist 1b}));

  // successful test
  .tst.resetCallog[];
  assert[`success;.qtb.priv.runTest[`b1`b2;`a1`a2`a3;`my`test]];
  exp_log1:([]
    funcname:`getSuite`countargs`executeSpecial`executeSpecial`resetCallog`tryThunk`executeSpecial`executeSpecial`executeSpecial;
    args:(
      `my`test;
      {[]};
      (`my`test;.qtb.cfg.specials.beforeEach;`b1);
      (`my`test;.qtb.cfg.specials.beforeEach;`b2);
      ::;
      {[]};
      (`my`test;.qtb.cfg.specials.afterEach;`a3);
      (`my`test;.qtb.cfg.specials.afterEach;`a2);
      (`my`test;.qtb.cfg.specials.afterEach;`a1)));
  assert[exp_log1;.tst.getCallog[]];

  // failed test
  .tst.resetCallog[];
  `.qtb.priv.tryThunk set {.tst.logCall[`tryThunk;x]; enlist 0b};
  assert[`failure;.qtb.priv.runTest[`b1`b2;`a1`a2`a3;`my`test]];
  assert[exp_log1;.tst.getCallog[]];
  `.qtb.priv.tryThunk set {.tst.logCall[`tryThunk;x]; enlist 1b};

  // failure in after each
  .tst.resetCallog[];
  `.qtb.priv.executeSpecial set {.tst.logCall[`executeSpecial;(x;y;z)]; not all (y ~ .qtb.cfg.specials.afterEach;z ~ `a1)};
  assert[`errorAfterEach;.qtb.priv.runTest[`b1`b2;`a1`a2`a3;`my`test]];
  assert[exp_log1;.tst.getCallog[]];

  // failure in before each
  .tst.resetCallog[];
  `.qtb.priv.executeSpecial set {.tst.logCall[`executeSpecial;(x;y;z)]; not all (y ~ .qtb.cfg.specials.beforeEach;z ~ `b2)};
  assert[`errorBeforeEach;.qtb.priv.runTest[`b1`b2;`a1`a2`a3;`my`test]];
  assert[4#exp_log1;.tst.getCallog[]];
  
  .qtb.priv.revertOverrides ovrr;
  };

test_executeSpecial:{[]
  ovrr:.tst.applyOverrides (
    (`.qtb.priv.tryThunk;{.tst.logCall[`tryThunk;x]; enlist 1b});
    (`.qtb.priv.println;{.tst.logCall[`println;x];}));

  // successful run
  .tst.resetCallog[];
  assert[1b;.qtb.priv.executeSpecial[`my`path;`specialSpecial;{[] `somefunc}]];
  exp_log1:enlist `funcname`args!(`tryThunk;{[] `somefunc});
  assert[exp_log1;.tst.getCallog[]];

  // failed run 
  .tst.resetCallog[];
  `.qtb.priv.tryThunk set {.tst.logCall[`tryThunk;x]; (0b;"boo!")};
  assert[0b;.qtb.priv.executeSpecial[`my`path;`specialSpecial;{[] `somefunc}]];
  exp_log2:([] funcname:`tryThunk`println; args:({[] `somefunc};"my.path.specialSpecial threw exception: boo!"));
  assert[exp_log2;.tst.getCallog[]];  
  
  .qtb.priv.revertOverrides ovrr;
  };

// .qtb.priv.resultTree2Table
test_resultTree2Table:{[]
  tres:([] testname:(),/:`testa`testb; result:`succeeded`failed; time:1.2 0.01f);
  subsuite1:enlist `suitename`start`time`tests!(`te;2018.11.11D11:11:11.0;1.1;update (`te,/: testname) from tres);
  subsuite2:enlist `suitename`start`time`tests!(`st;2018.02.02D02:02:02.0;2.2;update (`st,/: testname) from tres);
  basesuite:`suitename`start`time`tests!(`root;2018.03.03D03:03:03.0;0.3;1 _ reverse subsuite2,subsuite1,reverse[tres],(::));
  res:.qtb.priv.resultTree2Table basesuite;
  exp_res:([]
    testname:`testa`testb`te.testa`te.testb`st.testa`st.testb;
    result:`succeeded`failed`succeeded`failed`succeeded`failed;
    time:1.2 0.01 1.2 0.01 1.2 0.01);
  assert[exp_res;res];
  };

// .qtb.priv.resultTree2JunitXml
test_resultTree2JunitXml:{[]
  tres:([] testname:`ctx,/:`testa`testb`testc; result:`success`failure`error; time:1.2 0.01 0f),(::);
  subsuite1:enlist `suitename`start`time`tests!(`root`te;2018.11.11D11:11:11.0;1.1;-1 _ tres);
  subsuite2:enlist `suitename`start`time`tests!(`root`st;2018.02.02D02:02:02.0;2.2;-1 _ tres);
  basesuite:`suitename`start`time`tests!((),`root;2018.03.03D03:03:03.0;0.3;(subsuite1,tres,subsuite2) 0 1 2 3 5);
  tresdoc:("  <testcase name=\"ctx.testa\" classname=\"\" time=\"1.200\" />";
           "  <testcase name=\"ctx.testb\" classname=\"\" time=\"0.010\">";"    <failure type=\"failed\"/>";"  </testcase>";
           "  <testcase name=\"ctx.testc\" classname=\"\" time=\"0.000\">";   "    <error type=\"error\"/>";"  </testcase>");
  rootsuite:"<testsuite name=\"root\" package=\"\" hostname=\"",string[.z.h],"\" errors=\"1\" failures=\"1\" tests=\"3\" timestamp=\"2018-03-03T03:03:03\" time=\"0.300\">";
  te_suite:"<testsuite name=\"root.te\" package=\"\" hostname=\"",string[.z.h],"\" errors=\"1\" failures=\"1\" tests=\"3\" timestamp=\"2018-11-11T11:11:11\" time=\"1.100\">";
  st_suite:"<testsuite name=\"root.st\" package=\"\" hostname=\"",string[.z.h],"\" errors=\"1\" failures=\"1\" tests=\"3\" timestamp=\"2018-02-02T02:02:02\" time=\"2.200\">";
  expdoc:raze {[td;ste] (ste;"  <properties />"),td,("  <system-out />";"  <system-err />";"</testsuite>")}[tresdoc] each (rootsuite;te_suite;st_suite);
  assert[expdoc;.qtb.priv.resultTree2JunitXml[0;basesuite]];
  };

test_parseCmdline:{[]
  baseres:`run`verbose`junit`debug!(0b;0b;`;0b);
  assert[baseres;.qtb.priv.parseCmdline ()];
  assert[@[baseres;`verbose;:;1b];.qtb.priv.parseCmdline enlist "-qtb-verbose"];
  assert[@[baseres;`verbose;:;1b];.qtb.priv.parseCmdline ("-qtb-verbose";(),"1")];
  assert[@[baseres;`run;:;1b];.qtb.priv.parseCmdline enlist "-qtb-run"];
  assert[@[baseres;`debug;:;1b];.qtb.priv.parseCmdline enlist "-qtb-debug"];
  assert[@[baseres;`junit`run;:;(`xxx;1b)];.qtb.priv.parseCmdline ("-qtb-junit";"xxx";"-qtb-run")];
  .qtb.priv.system:{1i};
  assert[@[baseres;`run`debug;:;11b];.qtb.priv.parseCmdline enlist "-qtb-run"];
  assert[@[baseres;`debug;:;1b];.qtb.priv.parseCmdline enlist "-qtb-debug"];
  .qtb.priv.system:system;
  };

test_reportResults:{[]
  res:([] path:`p1`p2`p3; result:`success`failure`success);
  ovrr:.tst.applyOverrides (
    (`.qtb.priv.writeTextFile;{.tst.logCall[`writeTextFile;(x;y)];});
    (`.qtb.priv.junitXmlDoc;{.tst.logCall[`junitXmlDoc;x]; 42});
    (`.qtb.priv.resultTree2Table;{.tst.logCall[`resultTree2Table;y]; x}[res]);
    (`.qtb.priv.show;{.tst.logCall[`show;x];}));

  .tst.resetCallog[];
  assert[res;.qtb.priv.reportResults[`outfile;`resultTree]];
  exp_log1:([]
    funcname:`junitXmlDoc`writeTextFile`resultTree2Table`show;
    args:(`resultTree;(`:outfile;42);`resultTree;res (),1));
  assert[exp_log1;.tst.getCallog[]];
  
  .qtb.priv.revertOverrides ovrr;
  };


test_parseCmdline:{[]
  baseres:(enlist "tgt.q";`run`verbose`debug`junit!(0b;0b;0b;`));
  ovrr:.tst.applyOverrides ((`.qtb.priv.system;{.tst.logCall[`system;x]; 0i});(`.qtb.priv.println;{.tst.logCall[`println;x];}));

  .tst.resetCallog[];
  assert[baseres;.qtb.priv.parseCmdline enlist "tgt.q"];
  assert[enlist `funcname`args!(`system;"e");.tst.getCallog[]];

  .tst.resetCallog[];
  assert[@[baseres;0;,;("foo";"bar")];.qtb.priv.parseCmdline ("tgt.q";"foo";"bar")];
  assert[enlist `funcname`args!(`system;"e");.tst.getCallog[]];

  assert[.[baseres;(1;`verbose);:;1b];.qtb.priv.parseCmdline " " vs "-verbose 1 tgt.q"];
  assert[.[baseres;(1;`debug);:;1b];.qtb.priv.parseCmdline " " vs "tgt.q -debug 1"];
  assert[.[baseres;(1;`run);:;1b];.qtb.priv.parseCmdline " " vs "tgt.q -run 1"];
  assert[.[baseres;(1;`junit);:;`afile.xml];.qtb.priv.parseCmdline " " vs "tgt.q -junit afile.xml"];
  `.qtb.priv.system set {.tst.logCall[`system;x]; 1i};
  assert[.[baseres;(1;`debug);:;1b];.qtb.priv.parseCmdline enlist "tgt.q"];

  .tst.checkEx1[.qtb.priv.parseCmdline;" " vs "-verbose 1 -debug 1 -run 1 -junit out.xml";"Missing target script argument(s)."];
  
  .qtb.priv.revertOverrides ovrr;
  };

test_runTests:{[]
  ovrr:.tst.applyOverrides (
    (`.qtb.priv.system;{.tst.logCall[`system;x]; $[x ~ "e";42;x in ("e 0";"e 1";"e 42");::;'"unexpected call to system"]});
    (`.qtb.priv.execute;{.tst.logCall[`execute;(x;y)]; `testResults});
    (`.qtb.priv.println;{.tst.logCall[`println;x];});
    (`.qtb.priv.reportResults;{.tst.logCall[`reportResults;(x;y)]; y}));

  // no debug, not verbose
  .tst.resetCallog[];
  assert[`testResults;.qtb.priv.runTests[0b;0b;`junit;`my`path]];
  exp_log1:([]
    funcname:`system`system`execute`system`println`reportResults;
    args:("e";"e 0";(0b;`my`path);"e 42";"";(`junit;`testResults)));
  assert[exp_log1;.tst.getCallog[]];

  // debug, verbose
  .tst.resetCallog[];
  assert[`testResults;.qtb.priv.runTests[1b;1b;`junit;`my`path]];
  exp_log2:([]
    funcname:`system`system`execute`system`reportResults;
    args:("e";"e 1";(1b;`my`path);"e 42";(`junit;`testResults)));
  assert[exp_log2;.tst.getCallog[]];
  
  .qtb.priv.revertOverrides ovrr;
  };

test_run:{[]
  ovrr:.tst.applyOverrides (
    (`.qtb.priv.scriptWithArgs;{[] .tst.logCall[`scriptWithArgs;::] 1b});
    (`.qtb.priv.parseCmdline;{.tst.logCall[`parseCmdline;x]; (("tgt.q";"script2.q");`run`debug`verbose`junit!(1b;0b;1b;`junit))});
    (`.qtb.priv.runTests;{[a;b;c;d] .tst.logCall[`runTests;(a;b;c;d)]; ([] result:`success`failure)});
    (`.qtb.priv.println;{.tst.logCall[`println;x];});
    (`.qtb.priv.system;{.tst.logCall[`system;x];});
    (`.qtb.priv.exit;{.tst.logCall[`exit;x];}));

  // normal mode, no exception, test failure
  .tst.resetCallog[];
  .qtb.run[];
  exp_log1:([] funcname:`scriptWithArgs`parseCmdline`system`system`runTests`exit; args:(::;();"l tgt.q";"l script2.q";(0b;1b;`junit;`$());0b));
  assert[exp_log1;.tst.getCallog[]];

  // normal mode, exception
  .tst.resetCallog[];
  `.qtb.priv.parseCmdline set {.tst.logCall[`parseCmdline;x]; (enlist "tgt.q";`run`debug`verbose`junit!(1b;0b;1b;`junit))};
  `.qtb.priv.runTests set {[a;b;c;d] .tst.logCall[`runTests;(a;b;c;d)]; '"hey!"};
  .qtb.run[];
  exp_log2:([] funcname:`scriptWithArgs`parseCmdline`system`runTests`println`exit; args:(::;();"l tgt.q";(0b;1b;`junit;`$());"Caught exception: hey!";0b));
  assert[exp_log2;.tst.getCallog[]];

  // debug mode, no exception, test success
  .tst.resetCallog[];
  `.qtb.priv.parseCmdline set {.tst.logCall[`parseCmdline;x] (enlist "tgt.q";`run`debug`verbose`junit!(1b;1b;1b;`junit))};
  `.qtb.priv.runTests set {[a;b;c;d] .tst.logCall[`runTests;(a;b;c;d)]; ([] result:`success`success)};
  .qtb.run[];
  exp_log3:([] funcname:`scriptWithArgs`parseCmdline`system`runTests; args:(::;();"l tgt.q";(1b;1b;`junit;`$())));
  assert[exp_log3;.tst.getCallog[]];
  
  // debug mode, exception
  .tst.resetCallog[];
  `.qtb.priv.runTests set {[a;b;c;d] .tst.logCall[`runTests;(a;b;c;d)]; '"oops!"};
  .tst.checkEx1[.qtb.run;::;"oops!"];
  assert[exp_log3;.tst.getCallog[]];
  
  .qtb.priv.revertOverrides ovrr;
  };

/////
if[not null .z.f;
  success:@[.tst.alltests;(::);{-1 "Exception from .tst.alltests: ",x; 0b}];
  exit `long$not success;
  ];
