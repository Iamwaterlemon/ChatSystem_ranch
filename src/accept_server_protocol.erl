%% Feel free to use, reuse and abuse the code in this file.

-module(accept_server_protocol).
-behaviour(gen_server).
-behaviour(ranch_protocol).
-include("../include/common.hrl").

%% API.
-export([start_link/4]).

%% gen_server.
-export([init/1]).
-export([init/4]).
-export([handle_call/3]).
-export([handle_cast/2]).
-export([handle_info/2]).
-export([terminate/2]).
-export([code_change/3]).

-define(TIMEOUT, 5000).

-record(state, {socket, transport}).


%% API.

start_link(Ref, Socket, Transport, Opts) ->
	proc_lib:start_link(?MODULE, init, [Ref, Socket, Transport, Opts]).

%% gen_server.

%% This function is never called. We only define it so that
%% we can use the -behaviour(gen_server) attribute.
init([]) -> {ok, undefined}.

init(Ref, Socket, Transport, _Opts = []) ->
	ok = proc_lib:init_ack({ok, self()}),
	ok = ranch:accept_ack(Ref),
	ok = Transport:setopts(Socket, [{active, once}, {packet, 2}]),
	gen_server:enter_loop(?MODULE, [],
		#state{socket = Socket, transport = Transport},
		?TIMEOUT).

handle_info({tcp, Socket, Data}, State=#state{
	socket=Socket, transport=Transport}) ->

	<<Key, Msg/binary>> = Data,
	%io:format("key:~p msg:~p~n", [Key, Msg]),
	case Key of
		?KEY_USER_INFO ->
			ChangeInfo = split_info(binary_to_list(Msg)),
			%io:format("the name of connected client is ~p:~n", [ChangeInfo]),
			client_manager_server:connect(Socket, ChangeInfo),
			{Name, _} = ChangeInfo,
			RoomAtom = room_manager_server:enter_room(Name, Socket),
			erlang:put(name, Name),
			erlang:put(room_id, RoomAtom);

		?KEY_PRIVATE_CHAT ->
			%私聊功能
			{NameToSend, PrivateMsg} = split_info(Msg),
			erlang:send(client_manager_server, {send_private_data, erlang:get(name), NameToSend, PrivateMsg}),
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
			erlang:send(erlang:get(room_id), {eating, erlang:get(name), Msg});
		%io:format("eating food!~n");

		?KEY_MOVING ->
			%走路功能
			<<NumX, NumY>> = Msg,
			%io:format("Msg: ~p~n", [binary_to_list(Msg)]),
			erlang:send(erlang:get(room_id), {moving, erlang:get(name), {NumX, NumY, erlang:get(room_id), Socket}});
		%io:format("walking to place!~n");

		?KEY_SLEEPING ->
			%睡觉功能
			erlang:send(erlang:get(room_id), {sleeping, erlang:get(name), Msg});
		%io:format("have sleep!~n");
		?KEY_CHANNEL ->
			<<Channel>> = Msg,
			client_manager_server:change_channel(Channel, erlang:get(name), Socket);
		_ ->
			error
	end,

	%case Transport:recv(Socket, 0, ?TIMEOUT) of
	%	{ok, Data} ->
			ok = Transport:setopts(Socket, [{active, once}, {packet, 2}]),
	%		erlang:send(erlang:self(), {tcp, Socket, Data});
	%	_ ->
	%		ok = Transport:close(Socket)
	%end,

	{noreply, State, ?TIMEOUT};


handle_info({tcp_closed, _Socket}, State) ->
	io:format("the client has close!!"),
	{stop, normal, State};

handle_info({tcp_error, _, Reason}, State) ->
	io:format("ERROR:~p~n", [Reason]),
	{stop, Reason, State};

handle_info(timeout, State) ->
	%io:format("the socket is waiting~n"),
	{noreply,State};
	%{stop, normal, State};

handle_info(_Info, State) ->
	{stop, normal, State}.

handle_call(_Request, _From, State) ->
	{reply, ok, State}.

handle_cast(_Msg, State) ->
	{noreply, State}.

terminate(_Reason, _State) ->
	ok.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.

%% Internal.

split_info(UserInfo) ->
	Pos = string:str(UserInfo, ":"),
	Name = string:sub_string(UserInfo, 1, Pos - 1),
	Password = string:sub_string(UserInfo, Pos + 1),
	{Name, Password}.
