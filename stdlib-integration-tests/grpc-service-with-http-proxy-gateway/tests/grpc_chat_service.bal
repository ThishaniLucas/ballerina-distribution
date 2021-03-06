// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
// This is server implementation for bidirectional streaming scenario

import ballerina/grpc;
import ballerina/log;
import ballerina/runtime;

// Server endpoint configuration
listener grpc:Listener ep3 = new (20007, {
      host: "localhost",
      secureSocket: {
          trustStore: {
              path: TRUSTSTORE_PATH,
              password: "ballerina"
          },
          keyStore: {
              path: KEYSTORE_PATH,
              password: "ballerina"
          }
      }
  });

@tainted final map<grpc:Caller> connectionsMap = {};

boolean initialized = false;

@grpc:ServiceConfig {name:"Chat"}
@grpc:ServiceDescriptor {
    descriptor: ROOT_DESCRIPTOR,
    descMap: getDescriptorMap()
}
service Chat on ep3 {

    resource function chat(grpc:Caller caller, stream<ChatMessage, error> clientStream) {
        log:print(string `${caller.getId()} connected to chat`);
        connectionsMap[caller.getId().toString()] = caller;
        log:print("Client registration completed. Connection map status");
        log:print("Map length: " + connectionsMap.length().toString());
        log:print(connectionsMap.toString());
        initialized = true;
        error? e = clientStream.forEach(function(ChatMessage chatMsg) {
            grpc:Caller conn;
            string msg = string `${chatMsg.name}: ${chatMsg.message}`;
            log:print("Server received message: " + msg);
            int waitCount = 0;
            while(!initialized) {
                runtime:sleep(1000);
                log:print("Waiting till connection initialize. status: " + initialized.toString());
                if (waitCount > 10) {
                    break;
                }
                waitCount += 1;
            }
            log:print("Starting message broadcast. Connection map status");
            log:print("Map length: " + connectionsMap.length().toString());
            log:print(connectionsMap.toString());
            foreach var [callerId, connection] in connectionsMap.entries() {
                conn = connection;
                grpc:Error? err = conn->send(msg);
                if (err is grpc:Error) {
                    log:printError("Error from Connector: " + err.message());
                } else {
                    log:print("Server message to caller " + callerId + " sent successfully.");
                }
            }
        });
        if (e is grpc:EOS) {
            string msg = string `${caller.getId()} left the chat`;
            log:print(msg);
            var v = connectionsMap.remove(caller.getId().toString());
            log:print("Starting client left broadcast. Connection map status");
            log:print("Map length: " + connectionsMap.length().toString());
            log:print(connectionsMap.toString());
            foreach var [callerId, connection] in connectionsMap.entries() {
                grpc:Caller conn;
                conn = connection;
                grpc:Error? err = conn->send(msg);
                if (err is grpc:Error) {
                    log:printError("Error from Connector: " + err.message());
                } else {
                    log:print("Server message to caller " + callerId + " sent successfully.");
                }
            }
        } else if (e is error) {
            log:printError("Error from Connector: " + e.message());
        }
    }
}

type ChatMessage record {
    string name = "";
    string message = "";
};
