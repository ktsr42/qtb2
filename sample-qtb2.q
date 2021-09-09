assert_undef:{[v] if[not () ~ key v;'string[v]," is defined"];};
assert_def:{[v] if[()  ~ key v;'string[v]," is not defined"];};

assert:{[ev;av] if[not (~) . eval each (ev;av);'"mismatch between ",string[ev]," and ",string av];};

.TEST.t_beforeAll:{[]
  assert_undef each `a`.rootV;
  `.root.init_all set 1b;
  };

.TEST.t_afterAll:{[]
  assert_def each `.root.init_all;
  assert_undef each `.root.init_each`a`.root.V`.root.suite1.init_all`.root.suite1.init_each`s1a`s1b`.root.suite2.init_all`.root.suite2.init_each`s2a`s2b;
  delete init_all from `.root;
  };

.TEST.t_beforeEach:{[]
  assert_def`.root.init_all;
  assert_undef `.root.init_each;
  `.root.init_each set 1b;
  };

.TEST.t_afterEach:{[]
  assert_def each `.root.init_all`.root.init_each`a`.root.V;
  delete init_each from `.root;
  }

.TEST.t_overrides:enlist (`a;42);
.TEST.t_mocks:enlist (`.root.V;{});

.TEST.testA:{[]
  assert_def each `.root.init_all`.root.init_each;
  assert_def `.root.V;
  assert[42;`a];
  `a` set 1000;
  .root.V[];
  .qtb.assert.callog enlist `funcname`args!(`.root.V;::);
  `.root.V set {x+y};
  };

.TEST.testB:{[]
  assert_def each `.root.init_all`.root.init_each;
  assert_def `.root.V;
  assert[42;`a];
  `a` set 1000;
  .root.V[];
  .qtb.assert.callog enlist `funcname`args!(`.root.V;::);
  `a set 2010;
  `.root.V set {(x;y)};
  };

.TEST.suite1.t_beforeAll:{[]
  assert_def `.root.init_all;
  assert_undef `.root.suite1.init_all;
  `.root.suite1.init_all set 1b;
  };

.TEST.suite1.t_afterAll:{[]
  assert_def each `.root.init_all`.root.suite1.init_all;;
  delete init_all from `.root.suite1;
  };

.TEST.suite1.t_beforeEach:{[]
  assert_def each `.root.init_all`.root.suite1.init_all;
  assert_undef `.root.suite1.init_each;
  `.root.suite1.init_each set 1b;
  };

.TEST.suite1.t_afterEach:{[]
  assert_def each `.root.init_all`.root.suite1.init_all`.root.suite1.init_each;
  delete init_each from `.root.suite1;
  };

.TEST.suite1.t_overrides:enlist (`s1a;42);
.TEST.suite1.t_mocks:enlist (`s1b;{x+y});

.TEST.suite1.testA:{[]
  assert_def each `.root.init_all`.root.suite1.init_all`.root.init_each`.root.suite1.init_each`a`.root.V`s1a`s1b;
  assert[42;`s1a]; assert[42;`a];
  .root.V[];
  assert[3;s1b[1;2]];
  .qtb.assert.callog ([] funcname:`.root.V`s1b; args:(::;1 2));
  `s1a set 1000;
  `s1b set `func;
  `a set 2001;
  `.root.V set 0n;
  };

.TEST.suite1.testB:{[]
  assert_def each `.root.init_all`.root.suite1.init_all`.root.init_each`.root.suite1.init_each`a`.root.V`s1a`s1b;
  assert[42;`s1a]; assert[42;`a];
  .root.V[];
  assert[3;s1b[1;2]];
  .qtb.assert.callog ([] funcname:`.root.V`s1b; args:(::;1 2));
  `s1a set 1001;
  `s1b set `funcB;
  `a set 3001;
  `.root.V set 0Np;
  };


.TEST.suite2.t_beforeAll:{[]
  assert_def `.root.init_all;
  assert_undef `.root.suite2.init_all;
  `.root.suite2.init_all set 1b;
  };

.TEST.suite2.t_afterAll:{[]
  assert_def each `.root.init_all`.root.suite2.init_all;;
  delete init_all from `.root.suite2;
  };

.TEST.suite2.t_beforeEach:{[]
  assert_def each `.root.init_all`.root.suite2.init_all;
  assert_undef `.root.suite2.init_each;
  `.root.suite2.init_each set 1b;
  };

.TEST.suite2.t_afterEach:{[]
  assert_def each `.root.init_all`.root.suite2.init_all`.root.suite2.init_each;
  delete init_each from `.root.suite2;
  };

.TEST.suite2.t_overrides:((`s2a;1024);(`s2b;2021.04m));

.TEST.suite2.testA:{[]
  assert_def each `.root.init_all`.root.suite2.init_all`.root.init_each`.root.suite2.init_each`a`.root.V`s2a`s2b;
  assert_undef each `.root.suite1.init_all`.root.suite1.init_each`s1a`s1b;
  assert[1024;`s2a]; assert[2021.04m;`s2b]; assert[42;`a];
  .root.V[];
  .qtb.assert.callog enlist `funcname`args!(`.root.V;::);
  `s2a set 1001;
  `s2b set `funcB;
  `a set 3001;
  `.root.V set 0Np;
  };


.TEST.suite2.testB:{[]
  assert_def each `.root.init_all`.root.suite2.init_all`.root.init_each`.root.suite2.init_each`a`.root.V`s2a`s2b;
  assert_undef each `.root.suite1.init_all`.root.suite1.init_each`s1a`s1b;
  assert[1024;`s2a]; assert[2021.04m;`s2b]; assert[42;`a];
  .root.V[];
  .qtb.assert.callog enlist `funcname`args!(`.root.V;::);
  `s2a set 0x00;
  `s2b set "hello";
  `a set 9001;
  `.root.V set 42;
  };

.TEST.suite3.testA:{[]
  assert_def each `.root.init_all`.root.init_each;
  assert[42;`a];
  .root.V[];
  .qtb.assert.callog enlist `funcname`args!(`.root.V;::);
  `a` set 1000;
  `.root.V set {x+y};
  };

.TEST.suite3.testB:{[]
  assert_def each `.root.init_all`.root.init_each;
  assert[42;`a];
  .root.V[];
  .qtb.assert.callog enlist `funcname`args!(`.root.V;::);
  `a set 2010;
  `.root.V set {(x;y)};
  };

