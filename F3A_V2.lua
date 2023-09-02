-- F3A call Version 1.0            16-08-2023
-- first version with leonardo, yaw and altitude 
-- simulation added (later needs to test if the DS-16 gen 1 mem is large enough to leave it in
-- thing to check location type (numbers are unclear)
-- 16-08-2023 ready for test flying and data generation from there fine tuning of the program

-- V2.0								18-08-2023
-- changed to location array and figure array 
-- figure array is in a for loop insted of if with counter
-- made all the cad drawing of the program to betermin the location array




-- voor arduino gebruik   "mavlinktoex_f3a_leonardo"

--------------------------------------------------------------------------------
local figurenr = 0
local figure = ""
local figureexit = ""
local figurerolls = "" 

local locationarraycounter = 1
local locationarraycounterold = 1

local GPSplaneangle = 0.0		-- angle of the line from pilot center to plane with the line from pilot to northpole
local planeangle = 0.0  		-- angle of the plane in the F3A box (left of center is positive)
local distance = 0.0			-- distance of the pilot to plane
local depth = 0.0				-- depth of the plane in the F3A box
local depthcountold = 0

local LATSeId, LATSePa = 0, 0	
local LONSeId, LONSePa = 0, 0
local ALTSeId, ALTSePa = 0, 0
local YAWSeId, YAWSePa = 0, 0

local strlatpilot = ""
local strlonpilot = ""
local centerangle = 0.0
	
local latplane = 0.0			-- latitude of the plane
local lonplane = 0.0			-- londitude of the plane
local strlatplane = ""			-- latitude of the plane
local strlonplane = ""			-- londitude of the plane
local altplane = 0.0			-- altitude of the plane
local yawplane = 0.0			-- yaw of the plane
local yawtype = 0    			-- 0 = unknown    1 = to center     2 = from center

local beep1OS = 0
local beep2OS = 0

local leftmin = 0.0
local leftmax = 0.0
local rightmin = 0.0
local rightmax = 0.0


local locationarray = {
				--min angle , max angle , min alt , max alt , 0 = don't care 1= to center 2 from center
				{20,50,25,100,1},		-- 1->2 	start
				{10,30,25,100,2},		-- 2->3 	half cuban 8
				{10,70,25,100,1},		-- 3->4 	top hat
				{30,50,25,75,2},		-- 4->5 	half square loop
				{10,45,200,300,1},		-- 5->6 	humpty bump
				{0,45,25,100,0},		-- 6->7 	humpty bump
				{10,45,200,300,2},		-- 7->8 	half squere loop on corner
				{20,70,25,75,1},		-- 8->9 	45 degree upline with 1.5 snap
				{20,45,200,300,2},		-- 9->10 	half 8 sided loop
				{30,70,25,75,1},		-- 10->11 	roll combo
				{30,70,25,100,2},		-- 11->12   pusshed immelman 
				{20,50,200,300,1},		-- 12->13	spin 2.5 turns 
				{10,45,25,75,2},		-- 13->14	humbty bump (end of box down)
				{20,70,150,300,0},		-- 14->15 	humbty bump (end of box down)
				{30,70,25,75,1},		-- 15->16 	figure ET
				{10,45,175,250,2},		-- 16->17   figure ET          new
				{5,55,25,125,0},		-- 17->18   figure ET		   changed
				{20,45,200,300,2},		-- 18->19	half squere loop 
				{10,70,25,100,1},		-- 19->20   figure M
				{20,45,25,75,2},		-- 20->21   figther turn
				{30,70,100,300,0},		-- 21->22	figther turn 	
				{10,45,25,75,1},		-- 22->23 	triangle
				{0,50,150,300,0},		-- 23->24 	triangle				
				{20,50,25,75,2},		-- 24->25 	shark fin				
				{40,70,150,300,0},		-- 25->26 	shark fin								
				{20,55,25,75,1},		-- 26->27 	loop											
				}
				
local figurearray = {
				--locationarray number , figure number, figure name , rolls, exit, main audio, second audio 
                --locationarray number figure will be called on the first clockcycle after the number changed
				{2  , 0, "Started" , "none", "normal", "/Audio/P23/00.0.wav", ""},  									--1
				{3  , 0, "Half cuban 8", "1x1/2", "normal", "/Audio/P23/00.1.wav", ""},  								--2
				{4  , 1, "Top hat", "2x1/4 1x1/2 2x1/4", "inverted", "/Audio/P23/01.0.wav", "/Audio/P23/01.1.wav"},  	--3
				{5  , 2, "Square loop", "1x1/2", "inverted", "/Audio/P23/02.0.wav", "/Audio/P23/02.1.wav"},				--4
				{6  , 3, "Humpty bump", "1x1 1x1/2", "normal", "/Audio/P23/03.0.wav", "/Audio/P23/03.1.wav"},			--5
				{8  , 4, "Half square loop 45", "2x1/2", "inverted", "/Audio/P23/04.0.wav", "/Audio/P23/04.1.wav"},		--6
				{9  , 5, "45 degree upline", "1.5 snap", "normal", "/Audio/P23/05.0.wav", "/Audio/P23/05.1.wav"}, 		--7
				{10 , 6, "Half 8 sided loop", "none", "inverted", "/Audio/P23/06.0.wav", "/Audio/P23/06.1.wav"}, 		--8
				{11 , 7, "roll combo", "2x1/2 2x1/2", "inverted", "/Audio/P23/07.0.wav", "/Audio/P23/07.1.wav"}, 		--9
				{12 , 8, "Pushed immelman", "1x1/2", "inverted", "/Audio/P23/08.0.wav", "/Audio/P23/08.1.wav"},			--10
				{13 , 9, "Iverted spin", "2.5 spin", "normal", "/Audio/P23/09.0.wav", "/Audio/P23/09.1.wav"},			--11
				{14 , 10, "Humpty bump", "1/4 1/4", "inverted", "/Audio/P23/10.0.wav", "/Audio/P23/10.1.wav"},			--12
				{16 , 11, "Figure ET", "1/2 1/2 1x1/4", "normal", "/Audio/P23/11.0.wav", "/Audio/P23/11.1.wav"},		--13
				{19 , 12, "Square loop", "1x1/2", "normal", "/Audio/P23/12.0.wav", "/Audio/P23/12.1.wav"}, 				--14
				{20 , 13, "Figure M", "1x1/4", "normal", "/Audio/P23/13.0.wav", "/Audio/P23/13.1.wav"},					--15
				{21 , 14, "Fighter turn", "2x1/4", "normal", "/Audio/P23/14.0.wav", "/Audio/P23/14.1.wav"},				--16
				{23 , 15, "Triangle", "1/2 2x1/4 2x1/4 1/2", "normal", "/Audio/P23/15.0.wav", "/Audio/P23/15.1.wav"},	--17
				{25 , 16, "Shark fin", "1/2 2x1/4", "inverted", "/Audio/P23/16.0.wav", "/Audio/P23/16.1.wav"},			--18
				{26 , 17, "Loop", "1/2 integ", "normal", "/Audio/P23/17.0.wav", "/Audio/P23/17.1.wav"},					--19
			}


local function readinputs()
		
    local templatplane = system.getSensorByID(LATSeId, LATSePa)
    local templonplane = system.getSensorByID(LONSeId, LONSePa)
	local tempaltplane = system.getSensorByID(ALTSeId, ALTSePa)
	local tempyawplane = system.getSensorByID(YAWSeId, YAWSePa)

	if(templatplane and templatplane.valid) then
		latplane = templatplane.value 
	else
		latplane = 0
	end
	if(templonplane and templonplane.valid) then
		lonplane = templonplane.value 
	else 
	    lonplane = 0
	end
	if(tempaltplane and tempaltplane.valid) then
       altplane = tempaltplane.value *10
	else
	    altplane = 0 
	end
	if(tempyawplane and tempyawplane.valid) then
        yawplane = tempyawplane.value * 10
	else
	    yawplane = 0 
	end	
	collectgarbage()	
end
-------------------------------------------------------------------- location calculations
local function checkplaneangle(value)
	if (value >360) then value = value - 360 end
	if (value <0) then value = value + 360 end	
	return value
end

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

local function flightcalculations()

	local strlattemp = string.format("%d",latplane)
	strlatplane = string.sub(strlattemp, 1, 2) .. "." .. string.sub(strlattemp, 3, 9) 

	local strlontemp = string.format("%d",lonplane)
    strlonplane = string.sub(strlontemp, 1, 1) .. "." .. string.sub(strlontemp, 2, 8) 
	
	local position1 = gps.newPoint(strlatplane, strlonplane)
	local position2 = gps.newPoint(strlatpilot, strlonpilot)
        
	GPSplaneangle = round(gps.getBearing(position2, position1),1)
	distance = round(gps.getDistance(position2, position1),0)

	planeangle = centerangle - GPSplaneangle
	if (planeangle < -180) then planeangle = planeangle +360 end 

	depth = round(math.cos(math.rad(planeangle))*distance,0)
		
	
	if(planeangle <= 0) then
		if ((leftmin > leftmax) and ((yawplane > leftmin) or (yawplane < leftmax))) or 
		   ((leftmin < leftmax) and ((yawplane > leftmin) and (yawplane < leftmax))) then 
					yawtype = 1 -- to center
		end
		if ((rightmin > rightmax) and ((yawplane > rightmin) or (yawplane < rightmax))) or 
		   ((rightmin < rightmax) and ((yawplane > rightmin) and (yawplane < rightmax))) then 
					yawtype = 2 -- from center
		end
	else
		if ((leftmin > leftmax) and ((yawplane > leftmin) or (yawplane < leftmax))) or 
		   ((leftmin < leftmax) and ((yawplane > leftmin) and (yawplane < leftmax))) then 
					yawtype = 2 -- from center
		end
		if ((rightmin > rightmax) and ((yawplane > rightmin) or (yawplane < rightmax))) or 
		   ((rightmin < rightmax) and ((yawplane > rightmin) and (yawplane < rightmax))) then 
					yawtype = 1 -- to center
		end
	end

	collectgarbage()
end	

local function staticcalculations()
    -- 70 is planeangle yaw offset
	leftmin = checkplaneangle( (centerangle - 90) - 70)
	leftmax = checkplaneangle( (centerangle - 90) + 70)
	rightmin = checkplaneangle( (centerangle + 90) - 70)
	rightmax = checkplaneangle( (centerangle + 90) + 70)
	collectgarbage()
end

-------------------------------------------------------------------- figure program
local function figureprogram()
	
	if ((math.abs (planeangle) > locationarray[locationarraycounter][1]) and 
		(math.abs (planeangle) < locationarray[locationarraycounter][2]) and
		(altplane > locationarray[locationarraycounter][3]) and
		(altplane < locationarray[locationarraycounter][4]) and
		((yawtype == locationarray[locationarraycounter][5]) or (locationarray[locationarraycounter][5] == 0))) then 
			locationarraycounter = locationarraycounter + 1		
	end
	
	for i,v in ipairs(figurearray) do 
		if ((v[1] == locationarraycounter) and (locationarraycounter ~= locationarraycounterold)) then 
			figurenr = v[2]
			figure = v[3]
			figurerolls = v[4]
			figureexit = v[5]
			system.playFile(v[6],AUDIO_IMMEDIATE)
			system.playFile(v[7],AUDIO_QUEUE)
			locationarraycounterold = locationarraycounter
		end
	end
	
	collectgarbage()
end

local function beep()
	if (((math.abs(planeangle) < 45) and (yawtype == 1)) or -- center of box
	    --((math.abs(planeangle) < 30) and (yawtype == 1)) or -- 2/6 of box from center
		--((math.abs(planeangle) > 30) and (yawtype == 2)) or 
		((math.abs(planeangle) > 45) and (yawtype == 2))) then
			if (beep1OS == 0) then system.playBeep (0, 2500, 200) end
			beep1OS = 1
	else
			beep1OS = 0	
	end
		
	if (math.abs(planeangle) < 8) then 
			if (beep2OS == 0) then system.playBeep (0, 1500, 400) end
			beep2OS = 1
	else
			beep2OS = 0				
    end
end

local function depthcall()
	-- if ((depth <= 140) or (depth >= 190)) then 
	if ((depth >= 180) and (system.getTimeCounter() >= (depthcountold + 250)) and (not system.isPlayback())) then 
			system.playNumber (depth/10, 0)
			print (depth/10)
			depthcountold = system.getTimeCounter()
	end
end

-------------------------------------------------------------------- main display
local function displayform() 
	lcd.drawText(5,3,"Fig :"..figure,FONT_MAXI)
	lcd.drawText(5,40,"figure rolls : "..figurerolls,FONT_BIG)
	lcd.drawText(9,62,"figure exit : "..figureexit,FONT_BIG)
	lcd.drawText(23,84,"figure nr : "..figurenr,FONT_BIG)
	
	lcd.drawText(5,108,"LAT : "..strlatplane,FONT_MINI)
	lcd.drawText(100,108,"LON : "..strlonplane,FONT_MINI)
	lcd.drawText(5,120,"Deg north : "..GPSplaneangle,FONT_MINI)
	lcd.drawText(37,132,"ALT : "..altplane,FONT_MINI)
	lcd.drawText(33,144,"YAW : "..yawplane,FONT_MINI)
	
	lcd.drawText(195,108,"loc counter : "..locationarraycounter,FONT_MINI)
	lcd.drawText(223,120,"depth : "..depth,FONT_MINI)	
	lcd.drawText(184,132,"offcenter deg : "..planeangle,FONT_MINI)
	lcd.drawText(209,144,"yawtype : "..yawtype,FONT_MINI)		
	collectgarbage()
end

-------------------------------------------------------------------- form location settings and sub functions
local function pilotpositionChanged()
    strlatpilot = strlatplane
	strlonpilot = strlonplane
	system.pSave("LATpilot", strlatpilot)
    system.pSave("LONpilot", strlonpilot)
end

local function centerangleset()
    centerangle = GPSplaneangle
	system.pSave("CENTERangle", centerangle *100)
end

local function centerangleChanged(value)
	centerangle = value /10
	system.pSave("CENTERangle", centerangle *100)
	staticcalculations()
end

local function initFormlocation(formID) 
 form.setButton(1,"reset",ENABLED)
 form.setButton(2,"set pp",ENABLED)
 form.setButton(3,"set cp",ENABLED)
 form.setButton(4,"fig 0",ENABLED)
end 

local function printFormlocation() 
 lcd.drawText(5,80,"plane location",FONT_MINI)
 lcd.drawText(5,90,"lat : "..strlatplane,FONT_MINI)
 lcd.drawText(5,100,"lng : "..strlonplane,FONT_MINI)
 lcd.drawText(5,110,"deg : "..GPSplaneangle,FONT_MINI)
 lcd.drawText(5,120,"yaw : "..yawplane,FONT_MINI)
 lcd.drawText(5,130,"alt : "..altplane,FONT_MINI)

 lcd.drawText(125,110,"pilot position",FONT_MINI)
 lcd.drawText(125,120,"lat : "..strlatpilot,FONT_MINI)
 lcd.drawText(125,130,"lng : "..strlonpilot,FONT_MINI)

 lcd.drawText(125,5,"center position",FONT_MINI)
 lcd.drawText(125,15,"deg : "..centerangle,FONT_MINI)
 
 lcd.drawText(5,5,"left yaw planeangle",FONT_MINI)
 lcd.drawText(5,15,"min deg :"..leftmin,FONT_MINI)
 lcd.drawText(5,25,"planeangle : "..checkplaneangle(centerangle-90),FONT_MINI)
 lcd.drawText(5,35,"max deg :"..leftmax,FONT_MINI)
 
 lcd.drawText(220,5,"right yaw planeangle",FONT_MINI)
 lcd.drawText(220,15,"min deg :"..rightmin,FONT_MINI)
 lcd.drawText(220,25,"planeangle : "..checkplaneangle(centerangle+90),FONT_MINI)
 lcd.drawText(220,35,"max deg :"..rightmax,FONT_MINI)
 
 lcd.drawText(220,110,"location status",FONT_MINI)
 lcd.drawText(220,120,"yawtype : "..yawtype,FONT_MINI)
 
 lcd.drawLine(150,35,150,105)
 lcd.drawLine(30,55,150,105)
 lcd.drawLine(270,55,150,105)
end 

local function keyPressedlocation(key) 
 if(key==KEY_1) then    --reset 
    strlatpilot = "0.0"
    strlonpilot = "0.0"
    centerangle = 0
 	staticcalculations()
 elseif(key == KEY_2) then -- set pilot position
    pilotpositionChanged()
 	staticcalculations()
 elseif(key == KEY_3) then -- set center angle
    centerangleset()
 	staticcalculations()
 elseif(key == KEY_4) then -- reset figure array
	arraycounter = 1
 end 
end 

-------------------------------------------------------------------- form general settings
local function initFormgeneral(formID) 
	form.addRow(1)
	form.addLabel({label="---   F3A call settings   ---", font=FONT_BIG})

    form.addRow(2)
    form.addLabel({label="Change center angle", width=220})
    form.addIntbox(centerangle *10 ,0,3600,0,1,1,centerangleChanged)

	form.addRow(2)
    form.addLabel({label="choose program", width=220})
    local program = {"P23","F23", "P25", "F25"}
	local programtype = 1
	form.addSelectbox(program,programtype,true,typeChanged,{width=190})


end 

local function getsensorid()
	local sensors = system.getSensors();
	for index,sensor in ipairs(sensors) do 
		if (sensor.label == "F3A_LAT") then 
			LATSeId = sensor.id
			LATSePa = sensor.param
		end
		if (sensor.label == "F3A_LON") then 
			LONSeId = sensor.id
			LONSePa = sensor.param
		end
		if (sensor.label == "F3A_ALT") then 
			ALTSeId = sensor.id
			ALTSePa = sensor.param
		end
		if (sensor.label == "F3A_YAW") then 
			YAWSeId = sensor.id
			YAWSePa = sensor.param
		end
	end 
	collectgarbage()
end

-------------------------------------------------------------------- logging
local function logging()

system.registerLogVariable("planeangle","deg",(
 function(index)
 return planeangle
 end)
)
system.registerLogVariable("GPSplaneangle","deg",(
 function(index)
 return GPSplaneangle
 end)
)
system.registerLogVariable("distance","m",(
 function(index)
 return distance
 end)
)
system.registerLogVariable("depth","m",(
 function(index)
 return depth
 end)
)
system.registerLogVariable("yawtype","",(
 function(index)
 return yawtype
 end)
)
system.registerLogVariable("locarraycounter","",(
 function(index)
 return locationarraycounter
 end)
)
system.registerLogVariable("figurenr","",(
 function(index)
 return figurenr
 end)
)
end

------------------------------------------------------------------- Runtime functions
local function loop()

	readinputs()													
	flightcalculations()
	figureprogram()
	beep()
	depthcall()
    collectgarbage()
end

------------------------------------------------------------------- Application initialization
local function init()   
	-- get system id's from telemety values
	getsensorid()
	--enable logging functions
	logging()
	-- register setting and telemety displays
	system.registerForm(1,MENU_MAIN,"F3A call location settings",initFormlocation,keyPressedlocation,printFormlocation); 
    system.registerForm(2,MENU_MAIN,"F3A call settings",initFormgeneral,nil,nil); 
	system.registerTelemetry(1,"F3A call",4,displayform)
    
	-- load settings from memory 	
	strlatpilot = 	system.pLoad("LATpilot", 0) 
	strlonpilot = 	system.pLoad("LONpilot", 0)
    centerangle =   system.pLoad("CENTERangle", 0) /100
	
	-- overwrite settings from memory MTA	
	strlatpilot = 	52.9204384
	strlonpilot = 	7.0677272 
	centerangle =   51.7

	-- overwrite settings from memory ACK
	--strlatpilot = 	52.60127
	--strlonpilot = 	4.775000
	--centerangle =   21.7

	-- calulation of satic location values
	staticcalculations()
	collectgarbage()
end

collectgarbage()
------------------------------------------------------------------- Application name
return {init=init, loop=loop, author="Ruud Kroes", version="2.0", name="F3A_test"}