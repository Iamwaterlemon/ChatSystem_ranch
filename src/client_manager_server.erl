%%%-------------------------------------------------------------------
%%% @author liuzixiang
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 十二月 2015 10:12
%%%-------------------------------------------------------------------
-module(client_manager_server).
-author("liuzixiang").

%%gen_server
-behavior(gen_server).
-export([start/0, stop/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-define(SERVER, ?MODULE).
-include("../include/common.hrl").

-export([connect/2, disconnect/1, change_channel/3]).

start() -> gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).
stop() -> gen_server:call(?MODULE, stop).
%% API

connect(Socket, UserInfo) -> gen_server:cast(?MODULE, {connect, Socket, UserInfo}).
disconnect(Name) -> gen_server:cast(?MODULE, {disconnet, Name}).
change_channel(Channel, Name, Socket) -> gen_server:cast(?MODULE, {change_channel, Channel, Name, Socket}).

init([]) ->
	erlang:put(name_list, []),
	{ok, io:format("client_manager_server init successed!")}.

handle_call(stop, _From, Pid) -> {stop, normal, stopped, Pid}.

handle_info({send_private_data, NameFrom, NameTo, PrivateMsg}, Pid) ->
	Data1 = list_to_binary([NameFrom, " say:" | PrivateMsg]),
	%[{_, _, Socket}] = ets:lookup(Tid, NameTo),
	{_, Socket} = erlang:get(NameTo),
	gen_tcp:send(Socket, Data1),
	{noreply, Pid};

handle_info({send_data, Data, Name, Channel}, Pid) ->
	Msg = list_to_binary([Name, " say:" | Data]),
	case Channel of
		?CHANNEL_WORLD ->
			do_send_public_data(Msg);

		_ ->
			do_send_message(Msg, Channel)
	end,
	{noreply, Pid}.



handle_cast({change_channel, Channel, Name, Socket}, Pid) ->
	erlang:put(Name, {Channel, Socket}),
	List = erlang:get(name_list),
	erlang:put(name_list, [Name | List]),
	{noreply, Pid};

handle_cast({connect, Socket, UserInfo}, Pid) ->
	{Name, Password} = UserInfo,
	io:format("Name:~p  Password;~p~n", [Name, Password]),
	case user_db:select(Name) of
		{atomic, [{Name, PasswordSave}]} ->
			if
				PasswordSave =:= Password ->
					io:format("验证通过!~n");
				true ->
					ok = gen_tcp:close(Socket),
					io:format("close client!~n")
			end;

		{atomic, []} -> user_db:add_new(Name, Password)
	end,
	{noreply, Pid};

handle_cast({disconnet, Name}, Pid) ->
	%ets:delete(Tid, Name),
	List = erlang:get(name_list),
	erlang:put(name_list, lists:delete(Name, List)),
	erlang:erase(Name),
	{noreply, Pid}.

%handle_cast(_Msg, State) -> {noreply, State}.
%handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.

do_send_message(Msg, Channel) ->
	case Channel of
		?CHANNEL_CHINA ->
			do_send_data(Channel, Msg);

		?CHANNEL_ENGLAND ->
			do_send_data(Channel, Msg);

		?CHANNEL_USA ->
			do_send_data(Channel, Msg)
	end.

do_send_data(Channel, Msg) ->
	SendData =
		fun(Name) ->
			{Country, Socket} = erlang:get(Name),
			if
				Country =:= Channel ->
					gen_tcp:send(Socket, Msg);
				true -> other
			end
		end,
	lists:foreach(SendData, erlang:get(name_list)).

do_send_public_data(Msg) ->
	SendData =
		fun(Name) ->
			{_, Socket} = erlang:get(Name),
			gen_tcp:send(Socket, Msg)
		end,
	lists:foreach(SendData, erlang:get(name_list)).