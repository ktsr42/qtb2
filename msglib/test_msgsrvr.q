.TEST.t_mocks:enlist (`lg;::);

// --- registerClient is trivial

// *** processRegistration
.TEST.processRegistration.t_mocks:((`isValidConnHandle;{1b});(`CONNS;([primaryAddress:`$()] clientHandle:`int$())));

.TEST.processRegistration.successful_add:{[]
  .qtb.assert.matches[1b;processRegistration[22;`me]];
  .qtb.assert.matches[([primaryAddress:el `me] clientHandle:el 22i);CONNS];
  .qtb.assert.callog enlist `funcname`args!(`lg;"Registering client with primary address me");
  };

.TEST.processRegistration.duplicate:{[]
  .qtb.override[`CONNS;([primaryAddress:el `me] clientHandle:el 22)];
  .qtb.assert.matches[1b;processRegistration[22;`me]];
  .qtb.assert.matches[([primaryAddress:el `me] clientHandle:el 22);CONNS];
  .qtb.assert.callog ([] funcname:`isValidConnHandle`lg; args:(22;"Re-registration from client me"));
  };

.TEST.processRegistration.replace:{[]
  .qtb.override[`CONNS;([primaryAddress:el `me] clientHandle:el 22)];
  .qtb.mock[`connectionDropped;::];
  .qtb.mock[`isValidConnHandle;{0b}];
  
  .qtb.assert.matches[1b;processRegistration[23;`me]];
  .qtb.assert.matches[([primaryAddress:el `me] clientHandle:el 23);CONNS];
  exp_log:([]
    funcname:`isValidConnHandle`lg`connectionDropped;
    args:(22;"Warning: Found invalid handle for primary address me, replacing registration";22));
  .qtb.assert.callog exp_log;
  };

.TEST.processRegistration.clash:{[]
  .qtb.override[`CONNS;conns:([primaryAddress:el `me] clientHandle:el 22)];
 
  .qtb.assert.matches[0b;processRegistration[33;`me]];
  .qtb.assert.matches[conns;CONNS];
  .qtb.assert.callog ([] funcname:`isValidConnHandle`lg; args:(22;"Failed registration for primary address me"));
  };

.TEST.processRegistration.nulladdr:{[]
  .qtb.assert.matches[0b;processRegistration[22;`]];
  .qtb.assert.callog enlist `funcname`args!(`lg;"regQuest for null (invalid) handle");
  };

// *** sendMessage
.TEST.sendMessage.t_mocks:((`CONNS;([primaryAddress:`me`you] clientHandle:10 11));(`isRegisteredClient;{[x;y] 1b});(`submitMessage;{[m;a;h]}));

.TEST.sendMessage.aok:{[]
  sendMessage[10;`me;`you;"are you ok?"];
  exp_log:([]
    funcname:`lg`isRegisteredClient`submitMessage`lg;
    args:("Message from me to you received: \"are you ok?\"";
      (10;`me);
      ((`receive;`me;`you;"are you ok?");`you;11);
      "Message forwarded"));
  .qtb.assert.callog exp_log;
  };

.TEST.sendMessage.notok:{[]
  sendMessage[10;`me;`him;"are you ok?"];
  exp_log:([]
    funcname:`lg`isRegisteredClient`lg;
    args:("Message from me to him received: \"are you ok?\"";(10;`me);"Unknown address, cannot forward message"));
  .qtb.assert.callog exp_log;
  };

.TEST.sendMessage.notregistered:{[]
  .qtb.mock[`isRegisteredClient;{[x;y] 0b}];
  sendMessage[10;`me;`him;"are you ok?"];
  exp_log:([]
    funcname:`lg`isRegisteredClient;
    args:("Message from me to him received: \"are you ok?\"";(10;`me)));
  .qtb.assert.callog exp_log;
  };


// *** submitMessage
.TEST.submitMessage.t_mocks:enlist (`send;{[h;m]});

.TEST.submitMessage.ok:{[]
  submitMessage["ayt?";`aclient;10];
  .qtb.assert.callog enlist `funcname`args!(`send;(10;"ayt?"));
  };

.TEST.submitMessage.fail:{[]
  .qtb.mock[`send;{[h;msg] '"oops!"}];
  submitMessage["dang!";`badboy;11];
  exp_log:([] funcname:`send`lg; args:((11;"dang!");"Failed to send message to client badboy: oops!"));
  .qtb.assert.callog exp_log;
  };


// *** isRegisteredClient
.TEST.isRegisteredClient.t_overrides:enlist (`CONNS;1!enlist `primaryAddress`clientHandle!(`him;42));

.TEST.isRegisteredClient.ok:{[] isRegisteredClient[42;`him]; };

.TEST.isRegisteredClient.unreg:{[]
  .qtb.assert.matches[0b;isRegisteredClient[43;`her]];
  .qtb.assert.callog enlist `funcname`args!(`lg;"Received request from unregistered client her");
  };

.TEST.isRegisteredClient.invalid:{[]
  .qtb.assert.matches[0b;isRegisteredClient[10;`him]];
  .qtb.assert.callog enlist `funcname`args!(`lg;"Received request with invalid primary address him");
  };

// *** connectionDropped
.TEST.connectionDropped.t_overrides:enlist (`CONNS;1!enlist `primaryAddress`clientHandle!(`him;42));

.TEST.connectionDropped.validhandle:{[]
  connectionDropped 42i;
  .qtb.assert.equals[0;count exec primaryAddress from CONNS where clientHandle = 42];
  .qtb.assert.callog enlist `funcname`args!(`lg;"Client him closed the connection");
  };

.TEST.connectionDropped.invalidhandle:{[]
  connectionDropped 100i;
  .qtb.assert.equals[1;count select from CONNS where primaryAddress = `him,clientHandle = 42];
  .qtb.assert.callogEmpty[];
  };

.TEST.connectionDropped.sanitycheck:{[]
  .qtb.override[`CONNS;([primaryAddress:`a`b]; clientHandle:3 3i)];
  .qtb.mock[`die;::];
  connectionDropped 3i;
  exp_log:([] funcname:`die`lg; args:("Corrupt connection tracking";"Client a closed the connection"));
  .qtb.assert.callog exp_log;
  };

// *** receiveMsg

.TEST.receiveMsg.t_mocks:enlist (`.dispatch.call;{[x]});

.TEST.receiveMsg.ok:{[]
  receiveMsg[10;(`afunc;`arg)];
  exp_log:([]
    funcname:`lg`.dispatch.call`lg`lg;
    args:("Received msg `afunc`arg";(`afunc;10;`arg);"Successfully processed request, result: ::";"Request processing complete"));
  .qtb.assert.callog exp_log;
  };

.TEST.receiveMsg.error:{[]
  .qtb.mock[`.dispatch.call;{[req] '"whoops!"}];
  receiveMsg[3;(`afunc;`xx)];
  exp_log:([]
    funcname:`lg`.dispatch.call`lg`lg;
    args:("Received msg `afunc`xx";(`afunc;3;`xx);"Error evaluating request: whoops!";"Request processing complete"));
  .qtb.assert.callog exp_log;
  };

.TEST.receiveMsg.string:{[]
  receiveMsg[13;"afunc[`arg]"];
  exp_log:([]
    funcname:`lg`.dispatch.call`lg`lg;
    args:("Received msg \"afunc[`arg]\"";(`afunc;13;enlist `arg);"Successfully processed request, result: ::";"Request processing complete"));
  .qtb.assert.callog exp_log;
  };


