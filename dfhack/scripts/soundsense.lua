-- Log aditional info about events in fortress for use in soundsense or other tools.

log = io.open("ss_fix.log", "a")

function msg(m, c)
	dfhack.gui.showAnnouncement(m,dfhack.color(c))
	log:write(m)
	log:write("\n")
	log:flush()
	dfhack.println(m)
end

-- SEASON FIX

--403200 per year, 100800 per season

local season = math.floor(df.global.cur_year_tick/100800) 

if season == 0 then
	msg("�� ��������� ��������� �����.")
elseif season == 1 then
	msg("�� ��������� ��������� ����.")
elseif season == 2 then
	msg("�� ��������� ��������� �����.")
elseif season == 3 then
	msg("�� ��������� ��������� ����.")
end

-- WEATHER FIX

local raining = false
local snowing = false

for x=0, #df.global.current_weather-1 do
	for y=0, #df.global.current_weather[x]-1 do
		weather = df.global.current_weather[x][y]
		if weather == 1 then
			raining = true
		elseif weather == 2 then
			snowing = true
		end
	end
end

if (not snowing and not raining) then
	msg("������ �����������.")
elseif raining then
	msg("����� �����.")
elseif snowing then
	msg("�������� ������.")
end

-- Periodic checkups

local workshopTypes = { "��������� ����������", "���������� �������", "���������� ���������", "���������� ������������", "��������� ����������", "�������", "��������� �������", "���������� �������", "���������� ��������|", "������� ����������", "����� �������", "�������",  "��������", "����� ��������", "�������� �����", "���������", "�������", "������ ��������", "��������", "�����", "�������", "���������", "������", "�����������", "����������" }
local furnaceTypes = { "�������� ����", "���������", "�������������� ����", "���� ��� ������", "��������� ���������", "����. �����. ����", "��������� ����", "������� ����" }
local SkillRating_L = { "��������������", "����������", "����������", "������������", "������", "�������", "�����������", "������", "�������", "����������������", "��������", "�������", "������", "������ ������", "������� ������", "�����������" }
local Jobskill_L = { "�����", "�������", "�������", "�����", "��������", "������������", "����������", "����������� ����", "����������� ��������",  "���������� ����",  "������",  "��������",  "���������",  "����",  "�������",  "�������",  "�������",  "�������", "����������",  "�������",  "����",  "�����",  "�������", "�������", "�����",   "�������", "������������ �����",  "���������",  "�������",  "������",  "��������",  "�����������",  "������ �� ������",  "������ �� �����", "������ �� �������",  "���������",  "��������",  "������ �� �����",  "��������",  "������",  "���� � �����",  "��������",  "����������", "����������",  "����������",  "���������",  "����������",  "������� �������",  "������� ��������",  "�������",  "�������",   "����������",  "������",  "���������",  "��������",  "�������",  "�����",   "��������",  "����������",  "����������",  "��������",  "������",  "���������",  "���������",   "����� �� ��������",  "�������",  "������ ������",   "�������",   "������ ������",   "����������",  "�������� ������",   "������",  "�����������",   "���������",  "������� ���������",  "�������",  "�����������",  "��������",  "����",  "�����������",  "������",  "�����",  "������",  "���������",  "����������",  "������",  "�������",  "������������",   "����������",  "�����������",  "����������� �����",  "��������",  "����",  "����",  "������",  "�����������",  "����������",  "�����",  "�������",  "����",  "�������",  "�����",  "��������",  "��������",  "������",  "�������",  "���� ���������� ����������",  "��������",  "������� ������",   "��������",   "����������",  "������",  "�����������",  "��������",   "��������",  "��������" }

old_expedition_leader = nil
old_mayor = nil
siege = false
buildStates = {}
unit_skills = {}

first_run = true

local function event_loop()
	local units = df.global.world.units.active

	local expedition_leader = nil
	local mayor = nil
	
	old_siege = siege
	siege = false
	
	for i=0, #units-1 do
		local unit = units[i]
		if dfhack.units.isCitizen(unit) then
			positions = dfhack.units.getNoblePositions(unit)
			if positions ~= nil then
				for p=1, #positions do
					if positions[p].position.name[0] == "������������ ����������" then
						expedition_leader = unit
					elseif positions[p].position.name[0] == "���" then
						mayor = unit
					end
					--print(dfhack.TranslateName(dfhack.units.getVisibleName(unit)).." "..positions[p].position.name[0])
				end
			end
			
			if unit_skills[unit.id] == nil then
				unit_skills[unit.id] = {}
			end

			for _, skill in pairs(unit.status.current_soul.skills) do 
			
				local rating = skill.rating
				if rating > 15 then
					rating = 15 -- hide legendary+
				end
			
				if unit_skills[unit.id][skill.id] == nil then
					unit_skills[unit.id][skill.id] = {}
					unit_skills[unit.id][skill.id].rusty = false
					unit_skills[unit.id][skill.id].very_rusty = false
					unit_skills[unit.id][skill.id].proficient = false
					unit_skills[unit.id][skill.id].accomplished = false
					unit_skills[unit.id][skill.id].legendary = false
				end

				if rating == 15 and unit_skills[unit.id][skill.id].legendary == false then
					unit_skills[unit.id][skill.id].legendary = true
					unit_skills[unit.id][skill.id].accomplished = true
					unit_skills[unit.id][skill.id].proficient = true
					if not first_run then
						msg(dfhack.TranslateName(dfhack.units.getVisibleName(unit)).." ���� "..SkillRating_L[rating+1].." "..Jobskill_L[skill.id+1]..".")
					end
				end
				if rating == 10 and unit_skills[unit.id][skill.id].accomplished == false then
					unit_skills[unit.id][skill.id].accomplished = true
					unit_skills[unit.id][skill.id].proficient = true
					if not first_run then
						msg(dfhack.TranslateName(dfhack.units.getVisibleName(unit)).." ���� "..SkillRating_L[rating+1].." "..Jobskill_L[skill.id+1]..".")
					end
				end
				if rating == 5 and unit_skills[unit.id][skill.id].proficient == false then
					unit_skills[unit.id][skill.id].proficient = true
					if not first_run then
						msg(dfhack.TranslateName(dfhack.units.getVisibleName(unit)).." ���� "..SkillRating_L[rating+1].." "..Jobskill_L[skill.id+1]..".")
					end
				end
				
				local rusty = false
				if skill.rating > 0 and skill.rating * 0.5 <= skill.rusty then
					rusty = true
				end
				local very_rusty = false
				if skill.rating >= 4 and skill.rating * 0.75 <= skill.rusty then
					very_rusty = true
				end
				
				if very_rusty and unit_skills[unit.id][skill.id].very_rusty == false and not first_run then
					msg(dfhack.TranslateName(dfhack.units.getVisibleName(unit)).." ������ �������� "..SkillRating_L[rating+1].." "..Jobskill_L[skill.id+1]..".")
				end
				if very_rusty == false and unit_skills[unit.id][skill.id].very_rusty and not first_run then
					msg(dfhack.TranslateName(dfhack.units.getVisibleName(unit)).." ������ �� ������ �������� "..SkillRating_L[rating+1].." "..Jobskill_L[skill.id+1]..".")
				end
				if rusty and unit_skills[unit.id][skill.id].rusty == false and not first_run then
					msg(dfhack.TranslateName(dfhack.units.getVisibleName(unit)).." �������� "..SkillRating_L[rating+1].." "..Jobskill_L[skill.id+1]..".")
				end
				if rusty == false and unit_skills[unit.id][skill.id].rusty and not first_run then
					msg(dfhack.TranslateName(dfhack.units.getVisibleName(unit)).." ������ �� �������� "..SkillRating_L[rating+1].." "..Jobskill_L[skill.id+1]..".")
				end
				unit_skills[unit.id][skill.id].rusty = rusty
				unit_skills[unit.id][skill.id].very_rusty = very_rusty
				
			end
			
		end
		-- siege detection
		if unit.flags1.active_invader then
			siege = true
		end
	end
	
	if siege ~= old_siege and siege then
		msg("���� ���� ������ � ���!")
	elseif siege ~= old_siege and not siege then
		msg("����� ��������.")
	end

	if expedition_leader ~= old_expedition_leader then
		if expedition_leader == nil then
			msg("��������� ������������ ���������� ������ ��������.")
		else
			if not first_run then
				msg(dfhack.TranslateName(dfhack.units.getVisibleName(expedition_leader)).." ���� ������������� ����������.")
			end
		end
		old_expedition_leader = expedition_leader
	end
	
	if old_mayor == nil and expedition_leader == nil and mayor ~= nil then
		if not first_run then
			msg("������������ ���������� ��� ������ �����.")
		end
	end
	
	if mayor ~= old_mayor then
		if mayor == nil then
			msg("��������� ���� ������ ��������.")
		else
			if not first_run then
				msg(dfhack.TranslateName(dfhack.units.getVisibleName(mayor)).." ���� �����.")
			end
		end
		old_mayor = mayor
	end
	
	local buildings = df.global.world.buildings.all
	
	for i=0, #buildings-1 do
		local building = buildings[i]
		if getmetatable(building) == "building_workshopst" or getmetatable(building) == "building_furnacest" then
			if buildStates[building.id] == nil then
				buildStates[building.id] = building.flags.exists
			end
			local oldval = buildStates[building.id]
			if oldval ~= building.flags.exists then
				buildStates[building.id] = building.flags.exists
				if building.flags.exists then
					if getmetatable(building) == "building_workshopst" then
						msg(workshopTypes[building.type+1].." ���������.")
					elseif getmetatable(building) == "building_furnacest" then
						msg(furnaceTypes[building.type+1].." ���������.")
					end
				end
			end
		end
	end
	
	first_run = false
	
	dfhack.timeout(25, 'ticks', event_loop)
end

event_loop()

-- io.close(log)