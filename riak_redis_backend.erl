%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at

%%   http://www.apache.org/licenses/LICENSE-2.0


%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.    

%% @doc riak_redis_backend is a Riak storage backend using redis_drv.


-module(riak_redis_backend).
-author('Eric Cestari <eric@ohmforce.com').
-export([start/1,start/2,stop/1,get/2,put/3,list/1,list_bucket/2,delete/2]).


-define(RSEND(V), redis_send(fun()-> V end)).
% @type state() = term().
-record(state, {pid, partition}).

% @spec start(Partition :: integer()) ->
%                        {ok, state()} | {{error, Reason :: term()}, state()}
start(Partition)->
  {ok, Pid} = redis_drv:start_link(),
  P=list_to_binary(atom_to_list(node()) ++ integer_to_list(Partition)),
  {ok, #state{pid=Pid, partition = P}}.
  
start(Partition, _Config)->
  {ok, Pid} = redis_drv:start_link(),
  P=list_to_binary(atom_to_list(node()) ++ integer_to_list(Partition)),
  {ok, #state{pid=Pid, partition = P}}.

% @spec stop(state()) -> ok | {error, Reason :: term()}  
stop(_State)->
  ok.

% get(state(), Key :: binary()) ->
%   {ok, Val :: binary()} | {error, Reason :: term()}
get(#state{partition=P, pid=Pid}, BK)->
  case redis_drv:get(Pid, k2l(P,BK)) of
    nil -> {error, notfound};
    Val -> 
    case catch binary_to_term(Val) of
      {'EXIT', _}->
        throw({badterm, BK, Val});
      V ->
        {ok, V}
    end
  end.

% put(state(), Key :: binary(), Val :: binary()) ->
%   ok | {error, Reason :: term()}  
put(#state{partition=P, pid=Pid}, {Bucket, Key}=BK, Value)->
  %Fun = fun(_C)->
    % erldis:set_pipelining(Pid,true),
    redis_drv:sadd(Pid, <<"buckets:",P/binary>>,Bucket),
    redis_drv:set(Pid, k2l(P,BK), term_to_binary(Value)),
    redis_drv:sadd(Pid, <<P/binary,Bucket/binary>>, Key),
    redis_drv:sadd(Pid, <<"world:",P/binary>>, term_to_binary(BK)),
    % erldis:get_all_results(Pid),
    % erldis:set_pipelining(Pid,false),
    ok.
  %end,
  %case  erldis:exec(Pid, Fun) of
  %  [_,_, _, _] ->
  %    ok;
  %  _ ->
  %    {error, unable_to_put}
  %end.


% delete(state(), Key :: binary()) ->
%   ok | {error, Reason :: term()}
delete(#state {partition=P, pid=Pid}, {Bucket, Key}=BK) ->
  %Fun = fun(_C)->
    % redis_drv:set_pipelining(Pid,true),
    redis_drv:srem(Pid, <<"buckets:",P/binary>>,Bucket),
    redis_drv:del(Pid, k2l(P,BK)),
    redis_drv:srem(Pid, <<P/binary,Bucket/binary>>, Key),
    redis_drv:srem(Pid, <<"world:",P/binary>>, term_to_binary(BK)),
    % redis_drv:get_all_results(Pid),
    % redis_drv:set_pipelining(Pid,false),
  ok.
  %end,
  %case erldis:exec(Pid, Fun) of
  %  [_,_, _, _] ->
  %    ok;
  %  _ ->
  %    {error, unable_to_delete}
  %end.
  
% list(state()) -> [Key :: binary()]
list(#state {partition=P, pid=Pid}) ->
  lists:map(fun binary_to_term/1, 
      redis_drv:smembers(Pid, <<"world:",P/binary>>)).

list_bucket(#state{partition=P, pid=Pid}, '_')->
  redis_drv:smembers(Pid, <<"buckets:",P/binary>>);  
    
list_bucket(#state{partition=P, pid=Pid}, {filter, Bucket, Fun})->
  lists:filter(Fun, redis_drv:smembers(Pid, <<P/binary,Bucket/binary>>));
list_bucket(#state{partition=P, pid=Pid}, Bucket) ->
  redis_drv:smembers(Pid, <<P/binary,Bucket/binary>>).

k2l(P,{B, V})->
  <<P/binary,B/binary,V/binary>>.
