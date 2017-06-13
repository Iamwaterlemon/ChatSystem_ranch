%%%-------------------------------------------------------------------
%%% @author liuzixiang
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 十二月 2015 15:09
%%%-------------------------------------------------------------------
-module(client_server).
-author("liuzixiang").

-record(status, {name, socket, room_id}).
-behavior(gen_server).
-include("../include/common.hrl").
-export([start/2, stop/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-define(SERVER, ?MODULE).

%% API
start(Socket, Transport) -> gen_server:start_link(?MODULE, [Socket, Transport], []).
stop() -> gen_server:call(?MODULE, stop).

init([Socket, Transport]) ->
	X = #status{},
	{ok, UserInfo} = Transport:recv(Socket, 0, 5000),
	ChangeInfo = split_info(binary_to_list(UserInfo)),
	%io:format("the name of connected client is ~p:~n", [ChangeInfo]),
	client_manager_server:connect(Socket, ChangeInfo),
	{Name, _} = ChangeInfo,
	RoomAtom = room_manager_server:enter_room(Name, Socket),
	do_handle_client(Socket, Name, RoomAtom),
	{ok, X}.

handle_call(stop, _From, X) -> {stop, normal, stopped, X}.

%handle_cast(_Msg, State) -> {noreply, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.

do_handle_client(Socket, Name, RoomAtom) -> gen_server:cast(erlang:self(), {handle_client, Socket, Name, RoomAtom}).

handle_cast({handle_client, Socket, Name, RoomAtom}, P) ->
	X = #status{name = Name, socket = Socket, room_id = RoomAtom},
	case gen_tcp:recv(Socket, 0) of
		{ok, Data} ->

			<<Key, Msg/binary>> = Data,
			%io:format("key:~p msg:~p~n", [Key, Msg]),
			case Key of
				?KEY_PRIVATE_CHAT ->
					%私聊功能
					{NameToSend, PrivateMsg} = split_info(Msg),
					erlang:send(client_manager_server, {send_private_data, X#status.name, NameToSend, PrivateMsg}),
					io:format("private msg!  name:~p  msg:~p~n", [NameToSend, PrivateMsg]);
				?KEY_PUBLIC_CHAT ->
					%群聊功能
					%{Channel, PublicMsg} = split_info(Msg),
					%%将公共的消息发送到对应的频道
					%Channel = ?CHANNEL_WORLD,
					%erlang:send(client_manager_server, {send_data, Msg, X#status.name, Channel});
					ok;

				?KEY_EATING ->
					%吃饭功能
					erlang:send(X#status.room_id, {eating, X#status.name, Msg});
				%io:format("eating food!~n");

				?KEY_MOVING ->
					%走路功能
					<<NumX, NumY>> = Msg,
					%io:format("Msg: ~p~n", [binary_to_list(Msg)]),
					erlang:send(X#status.room_id, {moving, Name, {NumX, NumY, X#status.room_id, Socket}});
				%io:format("walking to place!~n");

				?KEY_SLEEPING ->
					%睡觉功能
					erlang:send(X#status.room_id, {sleeping, X#status.name, Msg});
				%io:format("have sleep!~n");
				?KEY_CHANNEL ->
					<<Channel>> = Msg,
					client_manager_server:change_channel(Channel, Name, Socket)
			end,

			do_handle_client(Socket, Name, RoomAtom);
		{error, closed} ->
			client_manager_server:disconnect(Name),
			erlang:exit(closed);

		_Any ->
			do_handle_client(Socket, Name, RoomAtom)
	end,
	{noreply, P}.

split_info(UserInfo) ->
	Pos = string:str(UserInfo, ":"),
	Name = string:sub_string(UserInfo, 1, Pos - 1),
	Password = string:sub_string(UserInfo, Pos + 1),
	{Name, Password}.




