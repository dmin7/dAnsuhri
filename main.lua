--------------------------------------------------------------
-- dAnushri drum generator
--
-- http://mutable-instruments.net/anushri
-- https://github.com/ashimoke/dRUMmACHINE/blob/master/code
--------------------------------------------------------------


local dialog = nil
local vb = nil
local notes = {"C-", "C#", "D-", "D#", "E-", "F-",
               "F#", "G-", "G#", "A-", "A#", "B-" }



--°°--
local opt = renoise.Document.create("ScriptingToolPreferences") {
  X = 0,
  Y = 0,
  BD = 45,
  SD = 25,
  HH = 140,
  BDNote = 48,
  SDNote = 50,
  HHNote = 54,
}
renoise.tool().preferences = opt


----------------------------------------------------
--°°-- ze stolen stuff
----------------------------------------------------
local BDcluster = { 
                    {236, 0, 0, 138, 0, 0, 208, 0, 58, 28, 174, 0, 104, 0, 58, 0},
                    {246, 10, 88, 14, 214, 10, 62, 8, 250, 8, 40, 14, 198, 14, 160, 120},
                    {224, 0, 98, 0, 0, 68, 0, 198, 0, 136, 174, 0, 46, 28, 116, 12},
                    {240, 204, 42, 0, 86, 108, 66, 104, 190, 22, 224, 0, 14, 148, 0, 36},
                    {228, 14, 36, 24, 74, 54, 122, 26, 186, 14, 96, 34, 18, 30, 48, 12},
                    {236, 24, 14, 54, 0, 0, 106, 0, 202, 220, 0, 178, 0, 160, 140, 8},
                    {236, 0, 226, 0, 0, 0, 160, 0, 0, 0, 188, 0, 0, 0, 210, 0},
                    {226, 0, 42, 0, 66, 0, 226, 14, 238, 0, 126, 0, 84, 10, 170, 22},
                    {228, 0, 212, 0, 14, 0, 214, 0, 160, 52, 218, 0, 0, 0, 134, 32}
                  }

local SDcluster = { 
                    { 10, 66, 0, 8, 232, 0, 0, 38, 0, 148, 0, 14, 198, 0, 114, 0},
                    { 16, 186, 44, 52, 230, 12, 116, 18, 22, 154, 10, 18, 246, 88, 72, 58},
                    { 0, 94, 0, 0, 224, 160, 20, 34, 0, 52, 0, 0, 194, 0, 16, 118},
                    { 0, 0, 112, 62, 232, 180, 0, 34, 0, 48, 26, 18, 214, 18, 138, 38},
                    { 2, 0, 46, 38, 226, 0, 68, 0, 2, 0, 92, 30, 232, 166, 116, 22},
                    {134, 82, 114, 160, 224, 0, 22, 44, 202, 220, 0, 178, 0, 160, 140, 8},
                    {134, 82, 114, 160, 224, 0, 22, 44, 66, 40, 0, 0, 192, 22, 14, 158},
                    { 0, 0, 54, 0, 182, 0, 128, 36, 6, 10, 84, 10, 238, 8, 158, 26},
                    {104, 0, 22, 84, 230, 22, 0, 58, 6, 0, 138, 20, 220, 18, 176, 34}
                  }


local HHcluster = {
                    {154, 98, 244, 34, 160, 108, 192, 24, 160, 98, 228, 20, 160, 92, 194, 44},
                    {136, 130, 220, 64, 130, 120, 156, 32, 128, 112, 220, 32, 126, 106, 184, 88},
                    {228, 104, 138, 90, 122, 102, 108, 76, 196, 160, 182, 160, 96, 36, 202, 22},
                    {232, 186, 224, 182, 108, 60, 80, 62, 142, 42, 24, 34, 136, 14, 170, 26},
                    { 64, 12, 236, 128, 160, 30, 202, 74, 68, 28, 228, 120, 160, 28, 188, 82},
                    {174, 86, 230, 58, 124, 64, 210, 58, 160, 76, 224, 22, 124, 34, 194, 26},
                    {174, 86, 230, 58, 124, 64, 210, 58, 160, 76, 224, 22, 124, 34, 194, 26},
                    {240, 46, 218, 24, 232, 0, 96, 0, 240, 28, 204, 30, 214, 0, 64, 0},
                    {230, 26, 52, 24, 82, 28, 52, 118, 154, 26, 52, 24, 202, 212, 186, 196},
                  }

--°°-- update pattern
function update()
 local iter = renoise.song().pattern_iterator:lines_in_pattern_track(
                renoise.song().selected_pattern_index,
                renoise.song().selected_track_index)
 --
 local sector = 0
 if (opt.X.value < 0 and opt.Y.value < 0) then sector = 1 end
 if (opt.X.value < 0 and opt.Y.value > 0) then sector = 2 end
 if (opt.X.value >= 0 and opt.Y.value >= 0) then sector = 3 end
 if (opt.X.value >= 0 and opt.Y.value <= 0) then sector = 4 end
 --
 --local Xmap = math.abs(opt.X.value / 100)
 --local Ymap = math.abs(opt.Y.value / 100)
 local Xmap = (opt.X.value + 100) / 200
 local Ymap = (opt.Y.value + 100) / 200
 --  
 local BDrum = 0
 local SDrum = 0
 local HHats = 0
 --
 for pos, line in iter do
  local tick = renoise.song().transport.lpb / 4
  line:clear()
   if (pos.line - 1) % tick == 0 then
    local p = (((pos.line - 1) / tick +3 ) % 16) + 1
    --print("position: " .. p .. " line: " .. pos.line)
    if sector == 1 then
      SDrum = (((SDcluster[1][p] * Xmap) + (SDcluster[2][p] * (1 - Xmap))) * Ymap ) 
        + (((SDcluster[4][p] * Xmap) + (SDcluster[5][p] * (1 - Xmap))) * ( 1 - Ymap))
      BDrum = (((BDcluster[1][p] * Xmap) + (BDcluster[2][p] * (1 - Xmap))) * Ymap ) 
        + (((BDcluster[4][p] * Xmap) + (BDcluster[5][p] * (1 - Xmap))) * ( 1 - Ymap))
      HHats = (((HHcluster[1][p] * Xmap) + (HHcluster[2][p] * (1 - Xmap))) * Ymap ) 
        + (((HHcluster[4][p] * Xmap) + (HHcluster[5][p] * (1 - Xmap))) * ( 1 - Ymap))
    elseif sector == 2 then
      SDrum = (((SDcluster[4][p] * Xmap) + (SDcluster[5][p] * (1 - Xmap))) * (1 - Ymap )) 
        + (((SDcluster[7][p] * Xmap) + (SDcluster[8][p] * (1 - Xmap))) * Ymap )
      BDrum = (((BDcluster[4][p] * Xmap) + (BDcluster[5][p] * (1 - Xmap))) * (1 - Ymap )) 
        + ( ( (BDcluster[7][p] * Xmap) + (BDcluster[8][p] * (1 - Xmap) ) ) * Ymap )
      HHats = (((HHcluster[4][p] * Xmap) + (HHcluster[5][p] * (1 - Xmap))) * (1 - Ymap )) 
        + ( ( (HHcluster[7][p] * Xmap) + (HHcluster[8][p] * (1 - Xmap) ) ) * Ymap )
    elseif sector == 3 then
      SDrum = (((SDcluster[5][p] * ( 1 - Xmap ) ) + (SDcluster[6][p] * Xmap ) ) * ( 1 - Ymap ) ) 
        + ( ( (SDcluster[8][p] * ( 1 - Xmap )) + (SDcluster[9][p] * Xmap ) ) * Ymap )
      BDrum = (((BDcluster[5][p] * ( 1 - Xmap ) ) + (BDcluster[6][p] * Xmap ) ) * ( 1 - Ymap ) ) 
        + ( ( (BDcluster[8][p] * ( 1 - Xmap )) + (BDcluster[9][p] * Xmap ) ) * Ymap )
      HHats = (((HHcluster[5][p] * ( 1 - Xmap ) ) + (HHcluster[6][p] * Xmap ) ) * ( 1 - Ymap ) ) 
        + ( ( (HHcluster[8][p] * ( 1 - Xmap )) + (HHcluster[9][p] * Xmap ) ) * Ymap )
    elseif sector == 4 then
      SDrum = (((SDcluster[2][p] * ( 1 - Xmap ) ) + (SDcluster[3][p] * Xmap ) ) * Ymap ) 
        + ( ( (SDcluster[5][p] * ( 1 - Xmap ) ) + (SDcluster[6][p] * Xmap ) ) * ( 1 - Ymap) )
      BDrum = (((BDcluster[2][p] * ( 1 - Xmap ) ) + (BDcluster[3][p] * Xmap ) ) * Ymap ) 
        + ( ( (BDcluster[5][p] * ( 1 - Xmap ) ) + (BDcluster[6][p] * Xmap ) ) * ( 1 - Ymap) )
      HHats = (((HHcluster[2][p] * ( 1 - Xmap ) ) + (HHcluster[3][p] * Xmap ) ) * Ymap ) 
        + ( ( (HHcluster[5][p] * ( 1 - Xmap ) ) + (HHcluster[6][p] * Xmap ) ) * ( 1 - Ymap) )
    end
     
    --line:clear()
    if BDrum < opt.BD.value then
      local nc = line:note_column(1)
      nc.note_value = vb.views.BDNote.value
      nc.volume_value = math.floor((1 - vb.views.VELimpact.value) * 128 + vb.views.VELimpact.value * BDrum / 255 * 128)
      if vb.views.BDInst.value < 0 then 
        nc.instrument_value = renoise.song().selected_instrument_index - 1
      else
        nc.instrument_value = vb.views.BDInst.value 
      end
    end
    if SDrum < opt.SD.value then
      local nc = line:note_column(2)
      nc.note_value = vb.views.SDNote.value
      nc.volume_value = math.floor((1 - vb.views.VELimpact.value) * 128 + vb.views.VELimpact.value * SDrum / 255 * 128)
      if vb.views.SDInst.value < 0 then 
        nc.instrument_value = renoise.song().selected_instrument_index - 1
      else
        nc.instrument_value = vb.views.SDInst.value 
      end
    end
    if HHats < opt.HH.value then
      local nc = line:note_column(3)
      nc.note_value = vb.views.HHNote.value
      nc.volume_value = math.floor((1 - vb.views.VELimpact.value) * 128 + vb.views.VELimpact.value * HHats / 255 * 128)
      if vb.views.HHInst.value < 0 then 
        nc.instrument_value = renoise.song().selected_instrument_index - 1
      else
        nc.instrument_value = vb.views.HHInst.value 
      end
    end
   end
  end
end



-- add menu entry
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:dAnushri v0.1 [test]...",
  invoke = function() show_dialog() end
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
  local RSIZE = 30

  local dialog_title = "dAnushri v0.1 [test]"

  
  -- dialog content 
  
  local dialog_content = vb:column {
    margin = DEFAULT_DIALOG_MARGIN,
    spacing = DEFAULT_CONTROL_SPACING,
    --uniform = true,
    --style = 'plain',
    vb:vertical_aligner {
     vb:row {
      --style = 'panel', 
      spacing = 12,
        --rotary: X
        vb:space {width=1},
        vb:column {
          vb:rotary {
            id = "X",
            midi_mapping = "dAnushri: X",
            width = RSIZE,
            height = RSIZE,
            min = -100,
            max = 100,
            bind = opt.X,
            notifier = function () update() end 
            },
          vb:text { text = "   X" },
          },
        --rotary: Y
        vb:column {
          vb:rotary {
            id = "Y",
            midi_mapping = "dAnushri: Y",
            width = RSIZE,
            height = RSIZE,
            min = -100,
            max = 100,
            bind = opt.Y,
            notifier = function () update() end 
            },
          vb:text { text = "   Y" },
          },
        --rotary: BD density
        vb:column {
          vb:rotary {
            id = "BD",
            midi_mapping = "dAnushri: BD",
            width = RSIZE,
            height = RSIZE,
            min = 0,
            max = 255,
            bind = opt.BD,
            notifier = function () update() end 
            },
          vb:text { text = "  BD" },
          },
        --rotary: SD density
        vb:column {
          vb:rotary {
            id = "SD",
            midi_mapping = "dAnushri: SD",
            width = RSIZE,
            height = RSIZE,
            min = 0,
            max = 255,
            bind = opt.SD,
            notifier = function () update() end 
            },
          vb:text { text = "  SD" },
          },
        --rotary: HH density
        vb:column {
          vb:rotary {
            id = "HH",
            midi_mapping = "dAnushri: HH",
            width = RSIZE,
            height = RSIZE,
            min = 0,
            max = 255,
            bind = opt.HH,
            notifier = function () update() end 
            },
          vb:text { text = "  HH" },
          },
        --rotary: Velocity impact
        vb:column {
          vb:rotary {
            id = "VELimpact",
            midi_mapping = "dAnushri: Vel",
            width = RSIZE,
            height = RSIZE,
            min = 0,
            max = 1,
            value = 0,
            notifier = function (v)
              update()
            end 
            },
          vb:text { text = "Vel" },
          },
        --rotary: Swing
        vb:column {
          vb:rotary {
            id = "Swing",
            midi_mapping = "dAnushri: Swing",
            width = RSIZE,
            height = RSIZE,
            min = 0,
            max = 1,
            value = 0,
            notifier = function (v)
              renoise.song().transport.groove_enabled = true 
              renoise.song().transport.groove_amounts = {v, v, v, v}
            end 
            },
          vb:text { text = "Swing" },
          },
        },
        
     vb:horizontal_aligner {
      margin = 3,
      
      vb:text { font = "bold", text = "BD: " },
      vb:text { text = " Inst.: " },
      vb:valuebox {
        id = "BDInst",
        width = 60,
        value = -1,
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
          update()
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
          return tonumber(string.sub(str, 3)) * 12 + table.find(string.sub(str, 1, 2), notes) - 1
        end,
        notifier = function(v)
          update()
        end
        },
        
      vb:text { text = " Track: " },
      vb:valuebox {
        id = "BDTrack",
        active = false,
        width = 55,
        value = 0,
        min = 0,
        max = 119,
        tostring = function(value) 
          if value == 0 then return "sel" 
          else return "" .. value
          end
        end,
        tonumber = function(str) 
          if str == "sel" then return  
          else return tonumber(7)
          end
        end,
        notifier = function(v)
          print(v)
        end
        },
      
      }, 
     vb:horizontal_aligner {
      margin = 3,
      
      vb:text { font = "bold", text = "SD: " },
      vb:text { text = " Inst.: " },
      vb:valuebox {
        id = "SDInst",
        width = 60,
        value = -1,
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
          update()
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
          return tonumber(string.sub(str, 3)) * 12 + table.find(string.sub(str, 1, 2), notes) - 1
        end,
        notifier = function(v)
          update()
        end
        },
        
      vb:text { text = " Track: " },
      vb:valuebox {
        id = "SDTrack",
        active = false,
        width = 55,
        value = 0,
        min = 0,
        max = 119,
        tostring = function(value) 
          if value == 0 then return "sel" 
          else return "" .. value
          end
        end,
        tonumber = function(str) 
          if str == "sel" then return  
          else return tonumber(7)
          end
        end,
        notifier = function(v)
          update()
        end
        },
      
      }, 
     vb:horizontal_aligner {
      margin = 3,
      
      vb:text { font = "bold", text = "HH: " },
      vb:text { text = " Inst.: " },
      vb:valuebox {
        id = "HHInst",
        width = 60,
        value = -1,
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
          update()
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
          return tonumber(string.sub(str, 3)) * 12 + table.find(string.sub(str, 1, 2), notes) - 1
        end,
        notifier = function(v)
          update()
        end
        },
        
      vb:text { text = " Track: " },
      vb:valuebox {
        id = "HHTrack",
        active = false,
        width = 55,
        value = 0,
        min = 0,
        max = 119,
        tostring = function(value) 
          if value == 0 then return "sel" 
          else return "" .. value
          end
        end,
        tonumber = function(str) 
          if str == "sel" then return  
          else return tonumber(7)
          end
        end,
        notifier = function(v)
          print(v)
        end
        },
      
      },
     },
         

  }


  
  
  
  -- key_handler
  
  local function key_handler(dialog, key)
    -- ignore held keys
    if (key.repeated) then
      return
    end
    
    if (key.name == "esc") then
      dialog:close()
    
    end 
    
  end
  
  
  -- show
  
  dialog = renoise.app():show_custom_dialog(
    dialog_title, dialog_content, key_handler)


--°°-- midi mappings
    
if not renoise.tool():has_midi_mapping("dAnushri: X") then     
      renoise.tool():add_midi_mapping{
        name = "dAnushri: X",
        invoke = function(message)
            vb.views.X.value = message.int_value / 127 * 200 - 100
        end
      }
    end


if not renoise.tool():has_midi_mapping("dAnushri: Y") then     
      renoise.tool():add_midi_mapping{
        name = "dAnushri: Y",
        invoke = function(message)
            vb.views.Y.value = message.int_value / 127 * 200 - 100
        end
      }
    end

if not renoise.tool():has_midi_mapping("dAnushri: BD") then     
      renoise.tool():add_midi_mapping{
        name = "dAnushri: BD",
        invoke = function(message)
            vb.views.BD.value = message.int_value / 127 * 255
        end
      }
    end

if not renoise.tool():has_midi_mapping("dAnushri: SD") then     
      renoise.tool():add_midi_mapping{
        name = "dAnushri: SD",
        invoke = function(message)
            vb.views.SD.value = message.int_value / 127 * 255
        end
      }
    end

if not renoise.tool():has_midi_mapping("dAnushri: HH") then     
      renoise.tool():add_midi_mapping{
        name = "dAnushri: HH",
        invoke = function(message)
            vb.views.HH.value = message.int_value / 127 * 255
        end
      }
    end

if not renoise.tool():has_midi_mapping("dAnushri: Vel") then     
      renoise.tool():add_midi_mapping{
        name = "dAnushri: Vel",
        invoke = function(message)
            vb.views.VELimpact.value = message.int_value / 127 
        end
      }
    end

if not renoise.tool():has_midi_mapping("dAnushri: Swing") then     
      renoise.tool():add_midi_mapping{
        name = "dAnushri: Swing",
        invoke = function(message)
            vb.views.Swing.value = message.int_value / 127 
        end
      }
    end

if not renoise.tool():has_midi_mapping("dAnushri: BDNote") then     
      renoise.tool():add_midi_mapping{
        name = "dAnushri: BDNote",
        invoke = function(message)
            vb.views.BDNote.value = math.floor(message.int_value / 127 * 119)
        end
      }
    end

if not renoise.tool():has_midi_mapping("dAnushri: SDNote") then     
      renoise.tool():add_midi_mapping{
        name = "dAnushri: SDNote",
        invoke = function(message)
            vb.views.SDNote.value = math.floor(message.int_value / 127 * 119)
        end
      }
    end

if not renoise.tool():has_midi_mapping("dAnushri: HHNote") then     
      renoise.tool():add_midi_mapping{
        name = "dAnushri: HHNote",
        invoke = function(message)
            vb.views.HHNote.value = math.floor(message.int_value / 127 * 119)
        end
      }
    end

--°°-- ze end
end
