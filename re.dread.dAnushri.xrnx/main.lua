--------------------------------------------------------------


--[[ CHANGELOG:

  v0.1.1:
// ...existing code moved to re.dread.dAnushri.xrnx/main.lua ...

]]

-- CONFIG:
-- Random amount: DEFAULT = 32; MAX = 255
-- NOTE: Does not work as one would expect, better left alone

local RANDOM_AMOUNT = 32
local TOOL_ID = "dAnushri v0.2" --used for read/write settings!
local TRACK_NAMES = {"dA2: BD", "dA2: SD", "dA2: HH" }

-- WARNING: crab coding style ahead!
-- «°°»

local dialog = nil
local vb = nil
local notes = {"C-", "C#", "D-", "D#", "E-", "F-",
               "F#", "G-", "G#", "A-", "A#", "B-" }

--°°¬¬ prefs
local opt = renoise.Document.create("ScriptingToolPreferences") {
  X = 0,
  Y = 0,
  BD = 170,
  SD = 170,
  HH = 170,
  BDNote = 48,
  BDInst = -1,
  BDVel = 0,
  BDAcc = 0,
  SDNote = 50,
  SDInst = -1,
  SDVel = 0,
  SDAcc = 0,
  HHNote = 54,
  HHInst = -1,
  HHVel = 0,
  HHAcc = 0,
  swing = 0,
  track = 2, -- 1 = current
}

renoise.tool().preferences = opt

require 'resources'

-- interpolate values
function mix(a, b, bal)
  return (b * bal / 255) + (a * (255 - bal) / 255) 
end                 

-- get the 'level' of a single inst./step
function readDrumMap(step, inst, x, y)
  --rprint(drum_map)
  local i = math.floor(x / 64) + 1
  --print("i: " .. i)
  local j = math.floor(y / 64) + 1
  --print("j: " .. j)
  --print("step: " .. inst * 16 + step)
  local a = drum_map[i][j][inst * 16 + step]
  local b = drum_map[i + 1][j][inst * 16 + step]
  local c = drum_map[i][j + 1][inst * 16 + step]
  local d = drum_map[i + 1][j + 1][inst * 16 + step]
  return math.abs( mix( mix(a, b, x*3), mix (c, d, x*3), y*3) - 1)
end

-- find / create tracks
function get_tracks()
  local tracks = {}
    for i = 1,renoise.song().sequencer_track_count do
      local name = renoise.song().tracks[i].name
      local find = table.find(TRACK_NAMES, name)
      if find then tracks[find] = i end
    end
    for i_ = -3, -1 do --^ reversed to get BD .. HH
      local i = math.abs(i_) 
      if not tracks[i] then 
        local sel_track = renoise.song().selected_track_index
        renoise.song():insert_track_at(sel_track)
        renoise.song().tracks[sel_track].name = TRACK_NAMES[i]
      end
    end
  if #tracks == 3 then 
    return tracks
  else
    return get_tracks()
  end
end


-- write_settings() scheduled?
local dirty = false
-- midi mappings
local midi_cache = nil

-- app_idle handler
function app_idle_notifier()
  if midi_cache then
      midi_cache()
      midi_cache = nil
    end
  if dirty then
    write_settings()
    dirty = false
  end
end  

-- update / create settings in instrument name
function write_settings()
  local instr = 0
  for i = 1, #renoise.song().instruments do
    if string.sub(renoise.song().instruments[i].name, 0, string.len(TOOL_ID)) == TOOL_ID then
      instr = i
    end
  end
  if instr == 0 then
    renoise.song():insert_instrument_at(#renoise.song().instruments)
    instr = #renoise.song().instruments 
  end
  renoise.song().instruments[instr].name = TOOL_ID 
    .. string.format(":{%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s}",
      opt.X.value, opt.Y.value, opt.BD.value, opt.SD.value, opt.HH.value,
      opt.BDNote.value, opt.BDInst.value, opt.BDVel.value, opt.BDAcc.value,
      opt.SDNote.value, opt.SDInst.value, opt.SDVel.value, opt.SDAcc.value,
      opt.HHNote.value, opt.HHInst.value, opt.HHVel.value, opt.HHAcc.value,
      opt.swing.value, opt.track.value)
       
end


-- read settings from instrument name
function read_settings()
  local instr = 0
  for i = 1, #renoise.song().instruments do
    if string.sub(renoise.song().instruments[i].name, 0, string.len(TOOL_ID)) == TOOL_ID then
      instr = i
    end
  end
  if instr > 0 then
    local s_string = string.sub(renoise.song().instruments[instr].name, (string.len(TOOL_ID) + 2))
    local s_func = loadstring("return " .. s_string)
    if s_func then 
      local settings = s_func()
      if type(settings) == "table" then
        opt.X.value = settings[1] 
        opt.Y.value = settings[2] 
        opt.BD.value = settings[3]
        opt.SD.value = settings[4]
        opt.HH.value = settings[5]
        opt.BDNote.value = settings[6]
        opt.BDInst.value = settings[7]
        opt.BDVel.value = settings[8]
        opt.BDAcc.value = settings[9]
        opt.SDNote.value = settings[10]
        opt.SDInst.value = settings[11]
        opt.SDVel.value = settings[12]
        opt.SDAcc.value = settings[13]
        opt.HHNote.value = settings[14]
        opt.HHInst.value = settings[15]
        opt.HHVel.value = settings[16]
        opt.HHAcc.value = settings[17]
        opt.swing.value = settings[18]
        opt.track.value = settings[19]  -- no comment
        print("dAnushri: settings restored!") 
      end
    else print("dAnushri: settings corrupted!")  
    end
  end    
end



-- init random amounts 
local perturbation = {}

function rnd_update() 
  for i = 1, 3 do 
    perturbation[i] =  math.random(0, RANDOM_AMOUNT)
  end
end

rnd_update()

--°°-- write pattern
function write()
  dirty = true
  local rec = renoise.song().transport.edit_mode
  local tracks = get_tracks()
    for i = 1, 3 do
      local iter = renoise.song().pattern_iterator:lines_in_pattern_track(
                     renoise.song().selected_pattern_index, 
                     tracks[i])
      for pos, line in iter do
        if not rec then line:note_column(1):clear() end
        local tick = math.max(1, renoise.song().transport.lpb / 4)
        local play_pos = renoise.song().transport.playback_pos.line 
        if not rec and (pos.line - 1) % tick == 0 
          or rec and pos.line >= play_pos and (pos.line - 1) % tick == 0  then
          if rec then line:note_column(1):clear() end
          local step = (((pos.line - 1) / tick) % 16) + 1
          --print("line: " .. pos.line ..  " / step: " .. step)
          local instr_ = { "BD", "SD", "HH" }
          local level = readDrumMap(step, i - 1, opt.X.value, opt.Y.value)
          
          -- apply perturbation
          if i == 3 and step == 16 and not rec then 
            rnd_update() 
          end
          
          -- not making too much sense:
          --[[local ec = line:effect_column(1)
          print(ec.number_string)
          if ec.number_string == 'DA' then
            perturbation[i] = ec.amount_value
          else
            if step == 1 then
              ec.number_string = 'DA'
              ec.amount_value = perturbation[i]
            end
            if i == 3 and step == 16 and not rec then 
              rnd_update() 
            end
          end]]
          
          if level < 255 - perturbation[i] then
            level = level + perturbation[i]
          end
          if level > (255 - opt[instr_[i]].value) then -- level over threshold, trigger
            local nc = line:note_column(1)
            -- note
            nc.note_value = vb.views[instr_[i] .. "Note"].value
            -- instrument
            local instr = vb.views[instr_[i] .. "Inst"].value
            if instr < 0 then
              nc.instrument_value = renoise.song().selected_instrument_index - 1
            else
              nc.instrument_value = instr
            end
            -- volume
            local vel = vb.views[instr_[i] .. "_vel"].value
            local vol = math.min(128, math.floor((1 - vel) * 152 + vel * level / 2))
            -- apply accent
            local acc = vb.views[instr_[i] .. "_acc"].value
            if step % 2 == 0 then
              if acc < 0 then
                vol = vol * (acc + 1)
              end 
            else
              if acc > 0 then
                vol = vol * math.abs(acc - 1)
              end 
            end             
            nc.volume_value = vol
          end
        end
      end
    end
end






-- add menu entry
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:" .. TOOL_ID .. " ...",
  invoke = function() 
    -- register notifiers
    if not renoise.tool().app_new_document_observable:has_notifier(read_settings) then
      renoise.tool().app_new_document_observable:add_notifier(read_settings)
    end
    if not renoise.tool().app_idle_observable:has_notifier(app_idle_notifier) then
      renoise.tool().app_idle_observable:add_notifier(app_idle_notifier)
    end
    read_settings()
    --°°¬¬
    show_dialog() 
  end
}




------------------------------
-- ze gui
------------------------------
function show_dialog()

  if dialog and dialog.visible then
    dialog:show()
    return
  end

  vb = renoise.ViewBuilder()

  local DEFAULT_DIALOG_MARGIN = 
    renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local DEFAULT_CONTROL_SPACING = 
    renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local DEFAULT_BUTTON_HEIGHT =
    renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT   
  local RSIZE = 35
  local INST_SPACING = 30

  local dialog_title = TOOL_ID

  
  -- dialog content 
  
  local dialog_content = vb:column {
    margin = DEFAULT_DIALOG_MARGIN,
    spacing = DEFAULT_CONTROL_SPACING,
    --uniform = true,
    --style = 'plain',
    vb:vertical_aligner {
     vb:row {
      --style = 'panel', 
      spacing = 7,
        --rotary: X
        vb:space {width=1},
        vb:column {
          vb:rotary {
            id = "X",
            midi_mapping = "dAnushri: X",
            width = RSIZE,
            height = RSIZE,
            min = 0,
            max = 255,
            bind = opt.X,
            notifier = function () write() end 
            },
          vb:text { font = "bold", text = "   X" },
          },
        --rotary: Y
        vb:column {
          vb:rotary {
            id = "Y",
            midi_mapping = "dAnushri: Y",
            width = RSIZE,
            height = RSIZE,
            min = 0,
            max = 255,
            bind = opt.Y,
            notifier = function () write() end 
            },
          vb:text { font = "bold", text = "   Y" },
          },
        vb:space { width = 3 }, 
        --rotary: Swing
        vb:column {
          vb:rotary {
            id = "Swing",
            midi_mapping = "dAnushri: Swing",
            width = RSIZE,
            height = RSIZE,
            min = 0,
            max = 1,
            bind = opt.swing,
            notifier = function (v)
              renoise.song().transport.groove_enabled = true 
              renoise.song().transport.groove_amounts = {v, v, v, v}
            end 
            },
          vb:text {  text = "Swing" },
          },
        vb:space { width = 2 }, 
        --rotary: BD
        vb:column {
         vb:row { 
          vb:rotary {
            id = "BD",
            midi_mapping = "dAnushri: BD",
            width = RSIZE,
            height = RSIZE,
            min = 0,
            max = 255,
            bind = opt.BD,
            notifier = function () write() end 
            },
            vb:column {
              vb:rotary {
                id = "BD_vel",
                midi_mapping = "dAnushri: BD_Vel",
                width = RSIZE / 2,
                height = RSIZE / 2,
                min = 0,
                max = 1,
                bind = opt.BDVel,
                notifier = function (v)
                  write()
                end 
                },
              vb:rotary {
                id = "BD_acc",
                midi_mapping = "dAnushri: BD_Acc",
                width = RSIZE / 2,
                height = RSIZE / 2,
                min = -1,
                max = 1,
                bind = opt.BDAcc,
                notifier = function (v)
                  write()
                end 
                }
            },
           },
          vb:text { font = "bold", text = "   Kick" },
          },
        --rotary: SD
        vb:column {
         vb:row { 
          vb:rotary {
            id = "SD",
            midi_mapping = "dAnushri: SD",
            width = RSIZE,
            height = RSIZE,
            min = 0,
            max = 255,
            bind = opt.SD,
            notifier = function () write() end 
            },
            vb:column {
              vb:rotary {
                id = "SD_vel",
                midi_mapping = "dAnushri: SD_Vel",
                width = RSIZE / 2,
                height = RSIZE / 2,
                min = 0,
                max = 1,
                bind = opt.SDVel,
                notifier = function (v)
                  write()
                end 
                },
              vb:rotary {
                id = "SD_acc",
                midi_mapping = "dAnushri: SD_Acc",
                width = RSIZE / 2,
                height = RSIZE / 2,
                min = -1,
                max = 1,
                bind = opt.SDAcc,
                notifier = function (v)
                  write()
                end 
                }
            },
           },
          vb:text { font = "bold", text = "   Snare" },
          },
        --rotary: HH
        vb:column {
         vb:row { 
          vb:rotary {
            id = "HH",
            midi_mapping = "dAnushri: HH",
            width = RSIZE,
            height = RSIZE,
            min = 0,
            max = 255,
            bind = opt.HH,
            notifier = function () write() end 
            },
            vb:column {
              vb:rotary {
                id = "HH_vel",
                midi_mapping = "dAnushri: HH_Vel",
                width = RSIZE / 2,
                height = RSIZE / 2,
                min = 0,
                max = 1,
                bind = opt.HHVel,
                notifier = function (v)
                  write()
                end 
                },
              vb:rotary {
                id = "HH_acc",
                midi_mapping = "dAnushri: HH_Acc",
                width = RSIZE / 2,
                height = RSIZE / 2,
                min = -1,
                max = 1,
                bind = opt.HHAcc,
                notifier = function (v)
                  write()
                end 
                }
            },
            vb:column {
              vb:text { text = "Vel" },
              vb:text { text = "Acc" },
            }
           },
          vb:text { font = "bold", text = "   HiHat" },
          },
        },
     vb:space { height = 10 },
     
     vb:column {
      style = 'group', 
      spacing = 3,
      margin = 5,  
      width = '100%',
     vb:horizontal_aligner {
      margin = 3,
      visible = false,
      vb:text { text = "BD/SD/HH's to:   "},
      vb:switch {
        width = 160,
        items = {"Current Track", "Single Tracks" },
        bind = opt.track
      },
     },
     vb:horizontal_aligner {
      margin = 2,
      spacing = INST_SPACING,
      vb:text { font = "bold", text = "BD: " },
      vb:text { text = " Inst.: " },
      vb:valuebox {
        id = "BDInst",
        midi_mapping = "dAnushri: BDInst",
        width = 60,
        bind = opt.BDInst,
        min = -1,
        max = 128,
        tostring = function(value) 
          if value == -1 then return "sel" 
          else return ("0x%.2X"):format(value)
          end
        end,
        tonumber = function(str) 
          if str == "sel" then return -1 
          else return tonumber(str, 0x10)
          end
        end,
        notifier = function(v)
          write()
        end
        },
      vb:text { text = " Note: " },
      vb:valuebox {
        id = "BDNote",
        midi_mapping = "dAnushri: BDNote",
        width = 55,
        bind = opt.BDNote,
        min = 0,
        max = 119,
        tostring = function(value) 
          return notes[(value % 12) + 1] .. math.floor(value / 12)
        end,
        tonumber = function(str) 
          local oct = string.sub(str, 3)
          local note_str = string.sub(str, 1, 2)
          local find = nil
          for i = 1, #notes do
            if notes[i] == note_str then
              find = i
            end
          end
          if find then return tonumber(oct) * 12 + find - 1 end
        end,
        notifier = function(v)
          write()
        end
        },
      }, 
     vb:horizontal_aligner {
      margin = 2,
      spacing = INST_SPACING,
      
      vb:text { font = "bold", text = "SD: " },
      vb:text { text = " Inst.: " },
      vb:valuebox {
        id = "SDInst",
        midi_mapping = "dAnushri: SDInst",
        width = 60,
        bind = opt.SDInst,
        min = -1,
        max = 128,
        tostring = function(value) 
          if value == -1 then return "sel" 
          else return ("0x%.2X"):format(value)
          end
        end,
        tonumber = function(str) 
          if str == "sel" then return -1 
          else return tonumber(str, 0x10)
          end
        end,
        notifier = function(v)
          write()
        end
        },
      vb:text { text = " Note: " },
      vb:valuebox {
        id = "SDNote",
        midi_mapping = "dAnushri: SDNote",
        width = 55,
        bind = opt.SDNote,
        min = 0,
        max = 119,
        tostring = function(value) 
          return notes[(value % 12) + 1] .. math.floor(value / 12)
        end,
        tonumber = function(str) 
          local oct = string.sub(str, 3)
          local note_str = string.sub(str, 1, 2)
          local find = nil
          for i = 1, #notes do
            if notes[i] == note_str then
              find = i
            end
          end
          if find then return tonumber(oct) * 12 + find - 1 end
        end,
        notifier = function(v)
          write()
        end
        },
      
      }, 
     vb:horizontal_aligner {
      margin = 2,
      spacing = INST_SPACING,
      
      vb:text { font = "bold", text = "HH: " },
      vb:text { text = " Inst.: " },
      vb:valuebox {
        id = "HHInst",
        midi_mapping = "dAnushri: HHInst",
        width = 60,
        bind = opt.HHInst,
        min = -1,
        max = 128,
        tostring = function(value) 
          if value == -1 then return "sel" 
          else return ("0x%.2X"):format(value)
          end
        end,
        tonumber = function(str) 
          if str == "sel" then return -1 
          else return tonumber(str, 0x10)
          end
        end,
        notifier = function(v)
          write()
        end
        },
      vb:text { text = " Note: " },
      vb:valuebox {
        id = "HHNote",
        midi_mapping = "dAnushri: HHNote",
        width = 55,
        bind = opt.HHNote,
        min = 0,
        max = 119,
        tostring = function(value) 
          return notes[(value % 12) + 1] .. math.floor(value / 12)
        end,
        tonumber = function(str) 
          local oct = string.sub(str, 3)
          local note_str = string.sub(str, 1, 2)
          local find = nil
          for i = 1, #notes do
            if notes[i] == note_str then
              find = i
            end
          end
          if find then return tonumber(oct) * 12 + find - 1 end
        end,
        notifier = function(v)
          write()
        end
        },
       },
      },
     },
         

  }


  
  
  
  -- key_handler
  
  local function key_handler(dialog, key)
    return key    
  end
  
  
  -- show
  
  dialog = renoise.app():show_custom_dialog(
    dialog_title, dialog_content, key_handler)


--°°-- midi mappings

    
if not renoise.tool():has_midi_mapping("dAnushri: X") then     
      renoise.tool():add_midi_mapping{
        name = "dAnushri: X",
        invoke = function(message)
            midi_cache = function() vb.views.X.value = message.int_value * 2 end
        end
      }
    end


if not renoise.tool():has_midi_mapping("dAnushri: Y") then     
      renoise.tool():add_midi_mapping{
        name = "dAnushri: Y",
        invoke = function(message)
            midi_cache = function() vb.views.Y.value = message.int_value * 2 end
        end
      }
    end

if not renoise.tool():has_midi_mapping("dAnushri: Swing") then     
      renoise.tool():add_midi_mapping{
        name = "dAnushri: Swing",
        invoke = function(message)
            midi_cache = function() vb.views.Swing.value = message.int_value / 127 end
        end
      }
    end
    
if not renoise.tool():has_midi_mapping("dAnushri: BD") then     
      renoise.tool():add_midi_mapping{
        name = "dAnushri: BD",
        invoke = function(message)
            midi_cache = function() vb.views.BD.value = message.int_value * 2 end
        end
      }
    end

if not renoise.tool():has_midi_mapping("dAnushri: BD_Vel") then     
      renoise.tool():add_midi_mapping{
        name = "dAnushri: BD_Vel",
        invoke = function(message)
            midi_cache = function() vb.views.BD_vel.value = message.int_value / 127 end
        end
      }
    end
    
if not renoise.tool():has_midi_mapping("dAnushri: BD_Acc") then     
      renoise.tool():add_midi_mapping{
        name = "dAnushri: BD_Acc",
        invoke = function(message)
            midi_cache = function() vb.views.BD_acc.value = message.int_value / 64 - 1 end
        end
      }
    end

if not renoise.tool():has_midi_mapping("dAnushri: SD") then     
      renoise.tool():add_midi_mapping{
        name = "dAnushri: SD",
        invoke = function(message)
            midi_cache = function() vb.views.SD.value = message.int_value * 2 end
        end
      }
    end

if not renoise.tool():has_midi_mapping("dAnushri: SD_Vel") then     
      renoise.tool():add_midi_mapping{
        name = "dAnushri: SD_Vel",
        invoke = function(message)
            midi_cache = function() vb.views.SD_vel.value = message.int_value / 127 end
        end
      }
    end
    
if not renoise.tool():has_midi_mapping("dAnushri: SD_Acc") then     
      renoise.tool():add_midi_mapping{
        name = "dAnushri: SD_Acc",
        invoke = function(message)
            midi_cache = function() vb.views.SD_acc.value = message.int_value / 64 - 1 end
        end
      }
    end

if not renoise.tool():has_midi_mapping("dAnushri: HH") then     
      renoise.tool():add_midi_mapping{
        name = "dAnushri: HH",
        invoke = function(message)
            midi_cache = function() vb.views.HH.value = message.int_value * 2 end
        end
      }
    end

if not renoise.tool():has_midi_mapping("dAnushri: HH_Vel") then     
      renoise.tool():add_midi_mapping{
        name = "dAnushri: HH_Vel",
        invoke = function(message)
            midi_cache = function() vb.views.HH_vel.value = message.int_value / 127 end
        end
      }
    end
    
if not renoise.tool():has_midi_mapping("dAnushri: HH_Acc") then     
      renoise.tool():add_midi_mapping{
        name = "dAnushri: HH_Acc",
        invoke = function(message)
            midi_cache = function() vb.views.HH_acc.value = message.int_value / 64 - 1 end
        end
      }
    end


if not renoise.tool():has_midi_mapping("dAnushri: BDNote") then     
      renoise.tool():add_midi_mapping{
        name = "dAnushri: BDNote",
        invoke = function(message)
            midi_cache = function() vb.views.BDNote.value = math.floor(message.int_value / 127 * 119) end
        end
      }
    end

if not renoise.tool():has_midi_mapping("dAnushri: BDInst") then     
      renoise.tool():add_midi_mapping{
        name = "dAnushri: BDInst",
        invoke = function(message)
            midi_cache = function() vb.views.BDInst.value = math.floor(message.int_value / 127 * #renoise.song().instruments - 1) end
        end
      }
    end

if not renoise.tool():has_midi_mapping("dAnushri: SDNote") then     
      renoise.tool():add_midi_mapping{
        name = "dAnushri: SDNote",
        invoke = function(message)
            midi_cache = function() vb.views.SDNote.value = math.floor(message.int_value / 127 * 119) end
        end
      }
    end
    
if not renoise.tool():has_midi_mapping("dAnushri: SDInst") then     
      renoise.tool():add_midi_mapping{
        name = "dAnushri: SDInst",
        invoke = function(message)
            midi_cache = function() vb.views.SDInst.value = math.floor(message.int_value / 127 * #renoise.song().instruments - 1) end
        end
      }
    end

if not renoise.tool():has_midi_mapping("dAnushri: HHNote") then     
      renoise.tool():add_midi_mapping{
        name = "dAnushri: HHNote",
        invoke = function(message)
            midi_cache = function() vb.views.HHNote.value = math.floor(message.int_value / 127 * 119) end
        end
      }
    end
    
if not renoise.tool():has_midi_mapping("dAnushri: HHInst") then     
      renoise.tool():add_midi_mapping{
        name = "dAnushri: HHInst",
        invoke = function(message)
            midi_cache = function() vb.views.HHInst.value = math.floor(message.int_value / 127 * #renoise.song().instruments - 1) end
        end
      }
    end

--°°-- ze end
end
