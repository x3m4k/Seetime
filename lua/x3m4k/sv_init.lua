--[[

MIT License

Copyright (c) 2021 x3m4k

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

]]


local timeTempTable = {}

file.CreateDir( "seetime/players" )
if not file.Exists( "seetime_server.json", "DATA" ) then
	file.Write( 
		"seetime_server.json",
		'{"updateFreq": 60, "maxRequestsPerSecond": 2, "maxDistance": 256}'
	)
end

local C = util.JSONToTable( file.Read( "seetime_server.json", "DATA" ) or "{}" )

local isShuttingDown = false
local updateFreq = C.updateFreq or 60  -- Seconds
local maxRequestsPerSecond = C.maxRequestsPerSecond or 2

SetGlobalInt( "seetime_maxdistance", C.maxDistance or 256 )

local seetime_maxdistance_cvar = CreateConVar(
	"seetime_maxdistance",
	C.maxDistance or 256,
	FCVAR_NONE,
	"Sets max distance for player's info retrieving.",
	32,
	1024
)

cvars.AddChangeCallback( "seetime_maxdistance", function( cvar, old, new )
	if new == nil then
		seetime_maxdistance_cvar:SetInt( old )
		return
	end

	SetGlobalInt( "seetime_maxdistance", new )
end )

util.AddNetworkString( "Seetime_get" )
util.AddNetworkString( "Seetime_recieve" )
util.AddNetworkString( "Seetime_get_self" )
util.AddNetworkString( "Seetime_recieve_self" )

local requestsTable = {}

local function CheckRequestsLimit( s64 )
	if requestsTable[s64] == nil then
		requestsTable[s64] = 0
	end

	requestsTable[s64] = requestsTable[s64] + 1

	return requestsTable[s64] <= maxRequestsPerSecond
end

timer.Create( "Seetime_requests_timer", maxRequestsPerSecond * 1.1, 0, function()
	requestsTable = {}
end )

local function GetReadTotalTime( s64 )
	time = file.Read( "seetime/players/" .. s64 .. ".txt", "DATA" ) or 0
	return time
end

local function GetSetTimeDifference( uid )
	if timeTempTable[ uid ] == nil then
		timeTempTable[ uid ] = CurTime()
		return math.floor( updateFreq / 2 )
	end

	local currentTime = CurTime()

	local res = currentTime - timeTempTable[ uid ]

	timeTempTable[ uid ] = currentTime

	return res
end

local function GetConnectedTime( s64 )
	for i, v in ipairs( player.GetAll() ) do
		if v:SteamID64() == s64 then
			return v:TimeConnected()
		end
	end

	return 0
end

net.Receive( "Seetime_get_self", function( len, ply )
	if not CheckRequestsLimit( ply:SteamID64() ) then return end

	local targetSteam64 = ply:SteamID64()

	net.Start( "Seetime_recieve_self" )
	net.WriteUInt( GetReadTotalTime( targetSteam64 ), 32 )
	net.WriteUInt( GetConnectedTime( targetSteam64 ), 32 )
	net.Send( ply )
end )

net.Receive( "Seetime_get", function( len, ply )
	if not CheckRequestsLimit( ply:SteamID64() ) then return end

	local targetSteam64 = net.ReadString()

	net.Start( "Seetime_recieve" )
	net.WriteString( targetSteam64 )
	net.WriteUInt( GetReadTotalTime( targetSteam64 ), 32 )
	net.WriteUInt( GetConnectedTime( targetSteam64 ), 32 )
	net.Send( ply )
end )

-- If a player leaves, he might lose updateFreq playtime, I think that's acceptable.
timer.Create( "Seetime_timer", updateFreq, 0, function()
	if isShuttingDown then return end

	for i, v in ipairs( player.GetAll() ) do
		if isShuttingDown then return end -- shutdown might happen in this moment

		local s64 = v:SteamID64()
		local totalTime = GetReadTotalTime( s64 )
		local changedTime = GetSetTimeDifference( s64 )
		file.Write( "seetime/players/" .. s64 .. ".txt", math.floor(totalTime + changedTime) )
	end
end )

timer.Create( "Seetime_cache_timer", 3600, 0, function()
	timeTempTable = {}
end )

hook.Add( "ShutDown", "Seetime_ShutDown", function()
	isShuttingDown = true
end )