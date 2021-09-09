.TEST.priv.regResult.t_mocks:((`.msg.priv.LOGF;::);(`.msg.priv.dropConnection;::);(`.msg.priv.CONN_STATE;.msg.priv.CONN_STATE));

.TEST.priv.regResult.success:{[]
  `.msg.priv.CONN_STATE set `registration_pending;
  .msg.priv.regResult 1b;
  .qtb.assert.matches[`connected;.msg.priv.CONN_STATE];
  .qtb.assert.callog enlist `funcname`args!(`.msg.priv.LOGF;"Registration request result: 1"); 
  };

.TEST.priv.regResult.failure:{[]
  `.msg.priv.CONN_STATE set `registration_pending;
  .msg.priv.regResult 0b;
  .qtb.assert.matches[`registration_pending;.msg.priv.CONN_STATE];
  .qtb.assert.callog ([] funcname:`.msg.priv.LOGF`.msg.priv.dropConnection; args:("Registration request result: 0";(::))); 
  };

.TEST.priv.regResult.invalid:{[]
  `.msg.priv.CONN_STATE set `OTHER;
  .qtb.override[`.msg.priv.MSGSERVER;42];
  
  .msg.priv.regResult 1b;
  exp_log:([]
    funcname:`.msg.priv.LOGF`.msg.priv.LOGF`.msg.priv.dropConnection;
    args:("Registration request result: 1";"Received unexpected registration message, current state: OTHER";(::)));
  .qtb.assert.callog exp_log;
  };


.TEST.priv.receiveMsg.t_mocks:((`.dispatch.call;::);(`.msg.priv.MSGSERVER;42));

.TEST.priv.receiveMsg.notforus:{[]
  .msg.priv.receiveMsg[10;`yo];
  .qtb.assert.callogEmpty[];
  };

.TEST.priv.receiveMsg.success:{[]
  .msg.priv.receiveMsg[42;`yo];
  .qtb.assert.callog enlist `funcname`args!`.dispatch.call`yo;
  };

.TEST.priv.receiveMsg.fail:{[]
  .qtb.mock[`.msg.priv.LOGF;::];
  .qtb.mock[`.dispatch.call;{[x] '"kaboom"}];
  .msg.priv.receiveMsg[42;`yo];
  exp_log:([] funcname:`.dispatch.call`.msg.priv.LOGF; args:(`yo;"Message dispatch failed: kaboom"));
  .qtb.assert.callog exp_log;
  };



.TEST.priv.enqueue.t_mocks:((`.msg.priv.LOGF;::);(`.msg.priv.PRIM_ADDRESS;`me);(`.msg.priv.MESSAGES;([] srcAddr:enlist `; destAddr:enlist `; msg:enlist (::))));

.TEST.priv.enqueue.ok:{[]
  .msg.priv.enqueue[`him;`me;"Yo!"];
  .qtb.assert.matches[([] srcAddr:``him; destAddr:``me; msg:((::);"Yo!")); .msg.priv.MESSAGES];
  .qtb.assert.callog enlist `funcname`args!(`.msg.priv.LOGF;"Message received from him for me: \"Yo!\"");
  };

.TEST.priv.enqueue.notforus:{[]
  .msg.priv.enqueue[`him;`her;42];
  .qtb.assert.matches[([] srcAddr:enlist `; destAddr:enlist `; msg:enlist (::)); .msg.priv.MESSAGES];
  exp_log:([]
    funcname:`.msg.priv.LOGF`.msg.priv.LOGF;
    args:("Message received from him for her: 42";"Message is not addressed to us, ignoring"));
  .qtb.assert.callog exp_log;
  };


.TEST.priv.dropConnection.t_mocks:((`.msg.priv.LOGF;::);(`.msg.priv.connectionDropped;::);(`.msg.priv.MSGSERVER;42);(`.q.hclose;::));

.TEST.priv.dropConnection.ok:{[]
  .msg.priv.dropConnection[];
  exp_log:([]
    funcname:`.msg.priv.LOGF`.q.hclose`.msg.priv.connectionDropped;
    args:("Dropping server connection";42;42));
  .qtb.assert.callog exp_log;
  };

.TEST.priv.dropConnection.error:{[]
  .qtb.mock[`.q.hclose;{[conn] '"ace"}];
  .qtb.mock[`.msg.priv.ERREXITF;{[] '"jump"}];
  .qtb.assert.throws[(`.msg.priv.dropConnection;(::));"jump"];
  exp_log:([]
    funcname:`.msg.priv.LOGF`.q.hclose`.msg.priv.LOGF`.msg.priv.ERREXITF;
    args:("Dropping server connection";42;"Fatal error, hclose in dropConnection failed: ace";(::)));
  .qtb.assert.callog exp_log;
  };


.TEST.priv.connectionDropped.t_mocks:((`.msg.priv.LOGF;::);(`.msg.priv.MSGSERVER;.msg.priv.MSGSERVER);(`.msg.priv.RECONNECT;.msg.priv.RECONNECT);(`.msg.priv.connSetup;::));

.TEST.priv.connectionDropped.otherhandle:{[]
  `.msg.priv.MSGSERVER set 3;
  `.msg.priv.RECONNECT set 0b;
  .msg.priv.connectionDropped 4;
  .qtb.assert.matches[3;.msg.priv.MSGSERVER];
  .qtb.assert.callogEmpty[];
  };

.TEST.priv.connectionDropped.noreconnect:{[]
  `.msg.priv.MSGSERVER set 4;
  `.msg.priv.RECONNECT set 0b;
  .msg.priv.connectionDropped 4;
  .qtb.assert.matches[0N;.msg.priv.MSGSERVER];
  .qtb.assert.callog enlist `funcname`args!(`.msg.priv.LOGF;"Server has disconnected");
  };

.TEST.priv.connectionDropped.reconnect:{[]
  `.msg.priv.MSGSERVER set 5;
  `.msg.priv.RECONNECT set 1b;
  .msg.priv.connectionDropped 5;
  .qtb.assert.matches[0N;.msg.priv.MSGSERVER];
  exp_log:([]
    funcname:`.msg.priv.LOGF`.msg.priv.connSetup;
    args:("Server has disconnected";(::)));
  .qtb.assert.callog exp_log;
  };


.testmsgcl.base:{x;};
.testmsgcl.link1:{x;};
.testmsgcl.link2:{x;};

.TEST.priv.chainCallback.t_mocks:`.testmsgcl.base`.testmsgcl.link1`.testmsgcl.link2,\:(::);

.TEST.priv.chainCallback.t_beforeEach:.TEST.priv.chainCallback.t_afterEach:{[] delete testcallback from `.};

.TEST.priv.chainCallback.notdefined:{[]
  .msg.priv.chainCallback[`testcallback;.testmsgcl.base];
  testcallback 1;
  .qtb.assert.callog enlist `funcname`args!(`.testmsgcl.base;1);
  };

.TEST.priv.chainCallback.existing:{[]
  .msg.priv.chainCallback[`testcallback;.testmsgcl.base];
  .msg.priv.chainCallback[`testcallback;.testmsgcl.link1];
  testcallback `me;
  .qtb.assert.matches[([] funcname:`.testmsgcl.base`.testmsgcl.link1; args:(`me;`me));.qtb.getCallog[]];
  };

.TEST.priv.chainCallback.three:{[]
  .msg.priv.chainCallback[`testcallback;.testmsgcl.base];
  .msg.priv.chainCallback[`testcallback;.testmsgcl.link1];
  .msg.priv.chainCallback[`testcallback;.testmsgcl.link2];
  testcallback "a";
  exp_log:([] funcname:`.testmsgcl.base`.testmsgcl.link1`.testmsgcl.link2; args:"aaa");
  .qtb.assert.callog exp_log;
  };


.TEST.init.t_mocks:((`.msg.priv.SERVER_ADDRESS;.msg.priv.SERVER_ADDRESS);(`.msg.priv.PRIM_ADDRESS;.msg.priv.PRIM_ADDRESS);(`.msg.priv.RECONNECT;.msg.priv.RECONNECT);(`.msg.priv.CONNECT_TIMEOUT;.msg.priv.CONNECT_TIMEOUT);(`.msg.priv.connSetup;::));

.TEST.init.missingparams:{[]
  .qtb.assert.throws[(`.msg.init;`a`b!1 2);"msgclient: missing parameters"];
  .qtb.assert.callogEmpty[];
  };

.TEST.init.full:{[]
  reconnectflag:not .msg.priv.RECONNECT;
  .msg.init `server`primAddr`reconnect!(`myserver;`us;reconnectflag);
  .qtb.assert.matches[`myserver;.msg.priv.SERVER_ADDRESS];
  .qtb.assert.matches[`us;.msg.priv.PRIM_ADDRESS];
  .qtb.assert.matches[reconnectflag;.msg.priv.RECONNECT];
  .qtb.assert.matches[enlist `funcname`args!(`.msg.priv.connSetup;::);.qtb.getCallog[]];
  };


.TEST.sendMsg.t_mocks:((`.msg.priv.SERVER_ADDRESS;.msg.priv.SERVER_ADDRESS);(`.msg.priv.PRIM_ADDRESS;.msg.priv.PRIM_ADDRESS);(`.msg.priv.RECONNECT;.msg.priv.RECONNECT);(`.msg.priv.CONNECT_TIMEOUT;.msg.priv.CONNECT_TIMEOUT);(`.msg.priv.send;{[x;y]}));

.TEST.sendMsg.ok:{[]
  `.msg.priv.CONN_STATE set `connected;
  `.msg.priv.MSGSERVER set 42;
  `.msg.priv.PRIM_ADDRESS set `alice;
  if[.msg.priv.send ~ {[h;m] (neg h) m};'"nope!"];
  .msg.sendMsg[`bob;([] c:1 2)];
  .qtb.assert.callog enlist `funcname`args!(`.msg.priv.send;(42;(`sendMessage;`alice;`bob;([] c:1 2))));
  };

.TEST.sendMsg.noconn:{[]
  `.msg.priv.CONN_STATE set `registration_pending;
  `.msg.priv.MSGSERVER set 43;
  .qtb.assert.throws[(`.msg.sendMsg;(),`alice;"Yo!");"msgclient: not connected"];  
  .qtb.assert.callogEmpty[];
  };


.TEST.nextMsg.t_overrides:enlist (`.msg.priv.MESSAGES;.msg.priv.MESSAGES);

.TEST.nextMsg.get3msg:{[]
  m1:`srcAddr`destAddr`msg!(`you;`me;42);
  m2:`srcAddr`destAddr`msg!(`somebody;`me;"Here we go");
  m3:`srcAddr`destAddr`msg!(`her;`me;`a`b!10 20);
  `.msg.priv.MESSAGES upsert m1;
  `.msg.priv.MESSAGES upsert m2;
  `.msg.priv.MESSAGES upsert m3;
  msgs:enlist (::);
  msgs,:enlist .msg.nextMsg[];
  msgs,:enlist .msg.nextMsg[];
  msgs,:enlist .msg.nextMsg[];
  msgs,:enlist .msg.nextMsg[];
  msgs,:enlist .msg.nextMsg[];
  .qtb.assert.matches[(m1;m2;m3;();());1 _ msgs]
  .qtb.assert.matches[([] srcAddr:enlist `; destAddr:enlist `; msg:enlist (::));.msg.priv.MESSAGES];
  };

