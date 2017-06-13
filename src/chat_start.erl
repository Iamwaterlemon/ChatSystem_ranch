%%%-------------------------------------------------------------------
%%% @author liuzixiang
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 十二月 2015 14:57
%%%-------------------------------------------------------------------
-module(chat_start).
-author("liuzixiang").

%% API
-export([start_server/0]).

start_server() ->
	%发送开始时间给错误记录器
	error_logger:error_msg("chat server start at ~p~n", [calendar:local_time()]),
	%%创建socket表
	client_manager_server:start(),
	%%初始化数据库
	user_db:start_db(),
	%%启动房间
	room_manager_server:start_room(),
	%启动accept
	ranch_app:start(1, 2),
	accept_server_app:start(1,2).
	%启动监控器
	%%observer_roomserver:process_info().
