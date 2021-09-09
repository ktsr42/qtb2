.TEST.t_overrides:enlist (`.dispatch.FUNCTIONS;([name:enlist `] realname:enlist `; argTypes:enlist (::)));
  
.TEST.registerFunc.t_overrides:((`testfunc;{[a;b] a+b});(`answer;42));

.TEST.registerFunc.ok:{[]
  .dispatch.registerFunc[`name;`testfunc;(-7 -7h)];
  .qtb.assert.matches[([name:``name] realname:``testfunc; argTypes:((::);-7 -7h));.dispatch.FUNCTIONS];
  };

.TEST.registerFunc.undefined:{[] .qtb.assert.throws[(`.dispatch.registerFunc;(),`invalid;(),`notthere;-11h);"dispatch: function notthere is not defined"]; };

.TEST.registerFunc.notafunction:{[] .qtb.assert.throws[(`.dispatch.registerFunc;(),`nofunc;(),`answer;-11h);"dispatch: answer is not a function"]; };

.TEST.registerFunc.argmismatch:{[] .qtb.assert.throws[(`.dispatch.registerFunc;(),`msmatch;(),`testfunc;-11h);"dispatch: signature mismatch"]; };


.TEST.deregister.remove:{[]
  `.dispatch.FUNCTIONS upsert (`a;`b;-11h);
  .dispatch.deregister `a;
  .qtb.assert.matches[([name:enlist `] realname:enlist `; argTypes:enlist (::));.dispatch.FUNCTIONS];
  };

.TEST.deregister.donothing:{[]
  currFuncs:.dispatch.FUNCTIONS;
  .dispatch.deregister `notthere;
  .qtb.assert.matches[currFuncs;.dispatch.FUNCTIONS];
  };


.TEST.call.t_overrides:(
  (`.dpcall.testfunc1;{.qtb.logCall[`testfunc1;(x;y;z)]; 42});
  (`.dpcall.testfunc2;{.qtb.logCall[`testfunc2;x];         });
  (`.dpcall.testfunc3;{.qtb.logCall[`testfunc3;x];         });
  (`.dpcall.testfunc4;{.qtb.logCall[`testfunc4;::];        });
  (`.dpcall.testfunc5;{[a;b]   .qtb.logCall[`testfunc5;(a;b)];   });
  (`.dpcall.testfunc6;{[a;b;c] .qtb.logCall[`testfunc6;(a;b;c)]; });
  (`.dpcall.testfunc7;{[a;b;c] .qtb.logCall[`testfunc7;(a;b;c)]; });
  (`.dispatch.FUNCTIONS;([name:``tfA`tfB`tfC`tfD`tfE`tfF`tfG]
      realname:``.dpcall.testfunc1`.dpcall.testfunc2`.dpcall.testfunc3`.dpcall.testfunc4`.dpcall.testfunc5`.dpcall.testfunc6`.dpcall.testfunc7;
      argTypes:(::;-11 -7 10h;0N;-11h;();enlist (::);-11 -7 10h;-11 -6 -10h))));

.TEST.call.base:{[]
  0N!.dispatch.call (`tfA;`a;22;"yo!");
  .qtb.assert.callog enlist `funcname`args!(`testfunc1;(`a;22;"yo!"));
  };

.TEST.call.anyarg:{[]
  .dispatch.call (`tfB;1 2);
  .qtb.assert.callog enlist `funcname`args!(`testfunc2;1 2);
  };

.TEST.call.onearg:{[]
  .dispatch.call `tfC`xxx;
  .qtb.assert.callog enlist `funcname`args!(`testfunc3;`xxx);
  };

.TEST.call.noarg:{[]
  .dispatch.call `tfD;
  .qtb.assert.callog enlist `funcname`args!(`testfunc4;::);
  };

.TEST.call.unknown:{[]
  .qtb.assert.throws[(`.dispatch.call;(enlist;(),`hi;42));"dispatch: unknown function 'hi'"];
  .qtb.assert.callogEmpty[];
  };

.TEST.call.numargs:{[]
  .qtb.assert.throws[(`.dispatch.call;enlist`tfF`x);"dispatch: function 'tfF' requires 3 arguments"];
  .qtb.assert.callogEmpty[];
  };

.TEST.call.argtype:{[]
  .qtb.assert.throws[(`.dispatch.call;enlist`tfG`x`y`z);"dispatch: arg type mismatch"];
  .qtb.assert.callogEmpty[];
  };
