%%%-------------------------------------------------------------------
%%% @author liuzixiang
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 21. 十二月 2015 10:19
%%%-------------------------------------------------------------------
-module(test).
-author("liuzixiang").

%% API
-export([start/0, sleep/1, f/2, test/0]).
-record(todo, {name, password}).

start() ->
  {ok, LSocket} = gen_tcp:listen(8080, [binary, {packet, 2}, {active, false}]) ,
  {ok, Socket} = gen_tcp:accept(LSocket),
  {ok, Data} = gen_tcp:recv(Socket, 0),
  {Bin1, Bin2} = split_binary(Data, 1),
  io:format("~p~n~p~n", [Data, binary_to_list(Data)]),
  io:format("~p~n~p~n", [Bin1,Bin2]),
  io:format("~p~n~p~n", [binary_to_list(Bin1), binary_to_list(Bin2)]),
  gen_tcp:send(Socket, Bin2).

sleep(N) ->
  io:format("do something!~n"),
   timer:sleep(3000),
  if
    N =:= 0 -> exit;
    true -> sleep(N-1)
  end.

f(X, Y) ->
  [begin io:format("~p  ~p~n", [X, Y]) end || X <- [X-1, X, X+1], Y <- [Y-1, Y, Y+1]].

test() ->
 room_map:map_init(50).