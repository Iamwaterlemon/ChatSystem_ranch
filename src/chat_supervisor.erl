%%%-------------------------------------------------------------------
%%% @author liuzixiang
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. 十二月 2015 9:48
%%%-------------------------------------------------------------------
-module(chat_supervisor).
-author("liuzixiang").

%% API
-export([start/0, start_link/1, start_in_shell_for_testing/0, init/1]).
-behaviour(supervisor).

start() ->
  spawn(fun() ->
                supervisor:start_link({local,  ?MODULE}, ?MODULE, _Arg = [])
        end).

start_in_shell_for_testing() ->
  {ok, Pid} = supervisor:start_link({local, ?MODULE}, ?MODULE, _Arg = []),
   unlink(Pid).

start_link(Args) ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, Args).

init([]) ->
  {ok, {one_for_all, 3, 10},
    [{tag1,
      {accept_server, start_link, []},
      permanent,
      10000,
      worker,
      [accept_server]},

      {tag2,
        {client_manager_server, start_link, []},
        permanent,
        10000,
        worker,
        [client_manager_server]},

      {tag3,
        {room_manager_server, start_link, []},
        permanent,
        10000,
        worker,
        [room_manager_server]}
    ]}.