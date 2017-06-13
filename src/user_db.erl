%%%-------------------------------------------------------------------
%%% @author liuzixiang
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 十二月 2015 12:26
%%%-------------------------------------------------------------------
-module(user_db).
-author("liuzixiang").

%% API
-include_lib("stdlib/include/qlc.hrl").
-export([add_new/2, remove/1, select/1, start_db/0, stop_db/0]).


-record(userinfo,{name, password}).

start_db() ->
  %% 等待表的加载
  mnesia:create_schema([node()]),
  mnesia:start(),
  case mnesia:create_table(userinfo, [{attributes, record_info(fields, userinfo)}, {disc_copies, [node()]}]) of
    {atomic, ok} ->io:format("create success!");
    Other -> Other
  end,
  mnesia:wait_for_tables([userinfo], 2000).

stop_db() ->
  mnesia:stop().

do(Q) -> mnesia:transaction(fun() -> qlc:e(Q) end).

select(Name) ->
  do(qlc:q([{X#userinfo.name, X#userinfo.password} || X <- mnesia:dirty_read(userinfo, Name) ])).

add_new(Name, Password) ->
  Row = #userinfo{name = Name, password = Password},
  F = fun() -> mnesia:dirty_write(Row) end,
  mnesia:transaction(F).

remove(Tmp) ->
  Oid = {userinfo, Tmp},
  F = fun() -> mnesia:delete(Oid) end,
  mnesia:transaction(F).

