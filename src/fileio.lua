-- functions to read lines correctly for \r\n line endings
utf8 = require("utf8")
chars = {
"¹",
"²",
"³",
"⁴",
"⁵",
"⁶",
"⁷",
"⁸",
"\t",
"\n",
"ᵇ",
"ᶜ",
"\r",
"ᵉ",
"ᶠ",
"▮",
"■",
"□",
"⁙",
"⁘",
"‖",
"◀",
"▶",
"「",
"」",
"¥",
"•",
"、",
"。",
"゛",
"゜",
" ",
"!",
"\"",
"#",
"$",
"%",
"&",
"'",
"(",
")",
"*",
"+",
",",
"-",
".",
"/",
"0",
"1",
"2",
"3",
"4",
"5",
"6",
"7",
"8",
"9",
":",
";",
"<",
"=",
">",
"?",
"@",
"A",
"B",
"C",
"D",
"E",
"F",
"G",
"H",
"I",
"J",
"K",
"L",
"M",
"N",
"O",
"P",
"Q",
"R",
"S",
"T",
"U",
"V",
"W",
"X",
"Y",
"Z",
"[",
"\\",
"]",
"^",
"_",
"`",
"a",
"b",
"c",
"d",
"e",
"f",
"g",
"h",
"i",
"j",
"k",
"l",
"m",
"n",
"o",
"p",
"q",
"r",
"s",
"t",
"u",
"v",
"w",
"x",
"y",
"z",
"{",
"|",
"}",
"~",
"○",
"█",
"▒",
"🐱",
"⬇️",
"░",
"✽",
"●",
"♥",
"☉",
"웃",
"⌂",
"⬅️",
"😐",
"♪",
"🅾️",
"◆",
"…",
"➡️",
"★",
"⧗",
"⬆️",
"ˇ",
"∧",
"❎",
"▤",
"▥",
"あ",
"い",
"う",
"え",
"お",
"か",
"き",
"く",
"け",
"こ",
"さ",
"し",
"す",
"せ",
"そ",
"た",
"ち",
"つ",
"て",
"と",
"な",
"に",
"ぬ",
"ね",
"の",
"は",
"ひ",
"ふ",
"へ",
"ほ",
"ま",
"み",
"む",
"め",
"も",
"や",
"ゆ",
"よ",
"ら",
"り",
"る",
"れ",
"ろ",
"わ",
"を",
"ん",
"っ",
"ゃ",
"ゅ",
"ょ",
"ア",
"イ",
"ウ",
"エ",
"オ",
"カ",
"キ",
"ク",
"ケ",
"コ",
"サ",
"シ",
"ス",
"セ",
"ソ",
"タ",
"チ",
"ツ",
"テ",
"ト",
"ナ",
"ニ",
"ヌ",
"ネ",
"ノ",
"ハ",
"ヒ",
"フ",
"ヘ",
"ホ",
"マ",
"ミ",
"ム",
"メ",
"モ",
"ヤ",
"ユ",
"ヨ",
"ラ",
"リ",
"ル",
"レ",
"ロ",
"ワ",
"ヲ",
"ン",
"ッ",
"ャ",
"ュ",
"ョ",
"◜",
"◝",
"\0",
}
ords={}
for k,v in pairs(chars) do
   ords[v]=k
end

edgecases = {
    ["⬇"] = "⬇️",
    ["🅾"] = "🅾️",
    ["➡"] = "➡️",
    ["⬆"] = "⬆️",
    ["⬅"] = "⬅️"
} -- ^^^^^^^^^^ these are different characters. base256 :weirdelie:

local function cr_lines(s)
    return s:gsub('\r\n?', '\n'):gmatch('(.-)\n')
end

local function cr_file_lines(file)
    local s = file:read('*a')
    if s:sub(#s, #s) ~= "\n" then
        s = s .. "\n"
    end
    return cr_lines(s)
end

-- file handling

function loadpico8(filename)
    love.graphics.setDefaultFilter("nearest", "nearest")

    local file, err = io.open(filename, "rb")

    local data = {}

    data.palette = {
        {0,  0,  0,  255},
        {29, 43, 83, 255},
        {126,37, 83, 255},
        {0,  135,81, 255},
        {171,82, 54, 255},
        {95, 87, 79, 255},
        {194,195,199,255},
        {255,241,232,255},
        {255,0,  77, 255},
        {255,163,0,  255},
        {255,240,36, 255},
        {0,  231,86, 255},
        {41, 173,255,255},
        {131,118,156,255},
        {255,119,168,255},
        {255,204,170,255}
    }

    local sections = {}
    local cursec = nil
    for line in cr_file_lines(file) do
        local sec = string.match(line, "^__(%a+)__$")
        if sec then
            cursec = sec
            sections[sec] = {}
        elseif cursec then
            table.insert(sections[cursec], line)
        end
    end
    file:close()
        local p8font=love.image.newImageData("pico-8_font.png")
        local function toGrey(x,y,r,g,b,a)
            return r*194/255,g*195/255,b*199/255,a
        end
        p8fontGrey=love.image.newImageData(p8font:getWidth(),p8font:getHeight(),p8font:getFormat(),p8font)
        p8fontGrey:mapPixel(toGrey)
        local function get_font_quad(digit)
                if digit<10 then
                        return 8*digit,24,4,8
                else
                        return 8*(digit-9),48,4,8
                end
        end
    local spritesheet_data = love.image.newImageData(128, 128)
    for j = 0, spritesheet_data:getHeight() - 1 do
        local line = sections["gfx"] and sections["gfx"][j + 1] or "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
        for i = 0, spritesheet_data:getWidth() - 1 do
            local s = string.sub(line, 1 + i, 1 + i)
            local b = fromhex(s)
            local c = data.palette[b + 1]
            spritesheet_data:setPixel(i, j, c[1]/255, c[2]/255, c[3]/255, 1)
        end
    end

    -- for j =8,15 do
        -- for i = 0, 15 do
                --    local id=i+16*(j-8)
                    --  local d1=math.floor(id/16)
                    --  local d2=id%16
                     --spritesheet_data:paste(p8font,8*i,8*j,get_font_quad(d1))
                    --  spritesheet_data:paste(p8fontGrey,8*i,8*j,get_font_quad(d1))
                    --  spritesheet_data:paste(p8font,8*i+4,8*j,get_font_quad(d2))
        -- end
    -- end

    data.spritesheet = love.graphics.newImage(spritesheet_data)

    data.quads = {}
    for i = 0, 15 do
        for j = 0, 15 do
            data.quads[i + j*16] = love.graphics.newQuad(i*8, j*8, 8, 8, data.spritesheet:getDimensions())
        end
    end



    data.map = {}
    for i = 0, 127  do
        data.map[i] = {}
        for j = 0, 31 do
            local line = sections["map"] and sections["map"][j + 1] or "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
            local s = string.sub(line, 1 + 2*i, 2 + 2*i)
            data.map[i][j] = fromhex(s)
        end
        for j = 32, 63 do
            -- if project.moresprites then
                local i_ = i%64
                local j_ = i <= 63 and j*2 or j*2 + 1
                local line = sections["gfx"][j_ + 1] or "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
                local s = string.sub(line, 1 + 2*i_, 2 + 2*i_)
                data.map[i][j] = fromhex_swapnibbles(s)
            -- else
                -- data.map[i][j] = 0
            -- end
        end
    end
    
    local unwrappedmap = {}
    for j=32,63 do
        for i=0,127 do
            unwrappedmap[#unwrappedmap+1] = data.map[i][j]
        end
    end
    print(dumplua(px9.decompress(unwrappedmap)))
    -- px9_decomp()
    -- decomp here

    data.rooms = {}
    data.roomBounds = {}

    -- code: look for the magic comment
    local code = table.concat(sections["lua"], "\n")
    local evh = string.match(code, "%-%-@begin(.+)%-%-@end")
    local levels, mapdata
    if evh then
        -- cut out comments - loadstring doesn't parse them for some reason
        -- evh = string.gsub(evh, "%-%-[^\n]*\n", "")
        -- evh = string.gsub(evh, "//[^\n]*\n", "")
        -- WHY WAS THIS LINE HERE COMMENTS ARE -- ANYWAY

        local chunk, err = loadstring(evh)
        if not err then
            local env = {}
            chunk = setfenv(chunk, env)
            chunk()
            levels, mapdata = env.levels, env.mapdata

            data.moresprites = env.moresprites
        else
            print("error")
            print(err)
        end
    else
        print("something went very wrong")
    end


    rawmap = dumplua(mapdata)
    
    for i,v in pairs(mapdata) do

        if not (mapdata[i] == nil) then 

        local cvdata = ""
        -- convert to base256
        local idh = 0
        local index=1
        while index < utf8.len(mapdata[i])+1 do
            local offset = utf8.offset(mapdata[i],index)
            local nextstart = utf8.offset(mapdata[i],index+1)
            local idx = string.sub(mapdata[i],offset,nextstart -1)
            
            if edgecases[idx] ~= nil then 
                idx = edgecases[idx]
                index = index + 1
            end
            if ords[idx] == nil then
                print("char not in dataset")
                print(idx)
                cvdata = cvdata.."00"
            else
                cvdata = cvdata..tohex(tonumber(ords[idx])-1)
                idh = idh + 1
                if idh == 256 then
                    idh = 0
                end
                -- tohex(tonumber(ords[idx])-1)
            end
            index = index + 1
        end
        -- print("len is ".. string.len(cvdata))



        -- unpack zeros
        local ndt = ""
        local index = 1
        while index < string.len(cvdata) do
            local tile = fromhex(string.sub(cvdata,index,index+1))
            if tile == 0 then
                local amount = tonumber(fromhex(string.sub(cvdata,index+2,index+3)))
                local constructed = ""
                for exp=0,amount do
                    constructed = constructed.."00"
                end
                ndt = ndt..constructed
                index = index + 2
            else
                ndt = ndt..string.sub(cvdata,index,index+1)
            end
            index = index + 2
        end

        -- prevent crashes
        --     if tile == 0 then
        --         print("decompressing space")
        --         print(amount)
        --         local expanded = ""
        --         for exp=0,amount do
        --             expanded = expanded.."00"
        --         end
        --         print(index)
        --         local z = string.sub(cvdata,1,index-1)
        --         if index == 1 then
        --             z = ""
        --         end
        --         print("expaneed len is"..string.len(expanded))
        --         cvdata = z..expanded..string.sub(cvdata,index + string.len(expanded),string.len(cvdata))
        --         index = index + string.len(expanded) - 1
        --         print(cvdata)
        --         print(index)
        --     end
        
        --     index = index + 2
        -- end
        -- if string.len(ndt) < levels[i] 

        mapdata[i] = ndt
    end
    end


    mapdata = mapdata or {}

    -- flatten levels and mapdata
    local lvls = {}
    if levels then
        for n, s in pairs(levels) do
            table.insert(lvls, {n, s, mapdata[n]})
        end
    end
    table.sort(lvls, function(p1, p2) return p1[1] < p2[1] end)
    levels, mapdata = {}, {}
    for n, p in pairs(lvls) do
        levels[n] = p[2]
        mapdata[n] = p[3]
    end

    -- load levels
    if levels[1] then
        for n, s in pairs(levels) do
            local x, y, w, h, title,customexit,top,right,left,bottom = string.match(s, "^([^,]*),([^,]*),([^,]*),([^,]*),?([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*)$")
            x, y, w, h = tonumber(x), tonumber(y), tonumber(w), tonumber(h)
            local customexit = customexit == "true"
            if x and y and w and h then -- this confirms they're there and they're numbers
                data.roomBounds[n] = {x=x*128, y=y*128, w=w*16, h=h*16, title=title,customexit=customexit,top=top,right=right,left=left,bottom=bottom}
                if not (mapdata[n] == nil) then
                    while string.len(mapdata[n])/2 < w*16 * h*16 do
                        print("preventing crash")
                        mapdata[n] = mapdata[n].."00"
                    end
                end
            else
                print("wat", s)
            end
        end
    else
        for J = 0, 3 do
            for I = 0, 7 do
                local b = {x = I*128, y = J*128, w = 16, h = 16, title="",customexit=false,top="nil",right="nil",left="nil",bottom="nil"}
                table.insert(data.roomBounds, b)
            end
        end
    end
    -- load mapdata
    if mapdata then
        for n, levelstr in pairs(mapdata) do
            local b = data.roomBounds[n]
            if b then
                local room = newRoom(b.x, b.y, b.w, b.h)
                loadroomdata(room, levelstr)
                room.title = b.title
                room.customexit = b.customexit
                room.top = b.top
                room.right = b.right
                room.left = b.left
                room.bottom = b.bottom
                data.rooms[n] = room
            end
        end
    end

    -- fill rooms with no mapdata from p8 map
    for n, b in ipairs(data.roomBounds) do
        if not data.rooms[n] then
            local room = newRoom(b.x, b.y, b.w, b.h)
            room.hex=false
            room.title = b.title
            room.title = b.title
            room.customexit = b.customexit
            room.top = b.top
            room.right = b.right
            room.left = b.left
            room.bottom = b.bottom

            for i = 0, b.w - 1 do
                for j = 0, b.h - 1 do
                    local i1, j1 = div8(b.x) + i, div8(b.y) + j
                    if i1 >= 0 and i1 < 128 and j1 >= 0 and j1 < 64 then
                        room.data[i][j] = data.map[i1][j1]
                    else
                        room.data[i][j] = 0
                    end
                end
            end


            data.rooms[n] = room
        end
    end
    return data
end

function openPico8(filename)
    newProject()

    -- loads into global p8data as well, for spritesheet
    p8data = loadpico8(filename)
    project.rooms = p8data.rooms
    project.moresprites = p8data.moresprites

    app.openFileName = filename

    return true
end

function savePico8(filename)
    local map = fill2d0s(128, 64)

    for _, room in ipairs(project.rooms) do
        if not room.hex then
            local i0, j0 = div8(room.x), div8(room.y)
            for i = 0, room.w - 1 do
                for j = 0, room.h - 1 do
                    if map[i0+i] then
                        map[i0+i][j0+j] = room.data[i][j]
                    end
                end
            end
        end
    end

    local file = io.open(filename, "rb")
    if not file and app.openFileName then
        file = io.open(app.openFileName, "rb")
    end
    if not file then
        return false
    end

    local out = {}

    local ln = 1
    local gfxstart, mapstart
    for line in cr_file_lines(file) do
        table.insert(out, line)
        ln = ln + 1
    end
    file:close()

    local levels, mapdata = {}, {}
    for n = 1, #project.rooms do
        local room = project.rooms[n]
        levels[n] = string.format("%g,%g,%g,%g,%s,%s,%s,%s,%s,%s", room.x/128, room.y/128, room.w/16, room.h/16, room.title,room.customexit,room.top,room.right,room.left,room.bottom)

        if room.hex then
            mapdata[n] = dumproomdata(room)
        end
    end
    -- print(dumplua(mapdata))
    for i,v in pairs(mapdata) do
        if not (mapdata[i] == nil) then 
        local newmapdata = ""
        local index = 1
        while index < string.len(mapdata[i])+1 do
            local tile = fromhex(string.sub(mapdata[i],index,index+1))
            if tile == 0 then

                local start = index
                while fromhex(string.sub(mapdata[i],index,index+1)) == 0 do
                    index = index + 2
                    if ((index - start) / 2 - 1) >= 254 then
                            -- skip = true
                        break
                    end
                end

                newmapdata = newmapdata.."00"..tohex(((index - start) / 2)-1)

                if skip then
                    index = index + 2
                end
            else
                newmapdata = newmapdata..tohex(tile)
                index = index + 2
            end
        end

        mapdata[i] = newmapdata

        local cvdata = ""

        for xindex=1, string.len(mapdata[i]),2 do
            local r = string.sub(mapdata[i],xindex,xindex+1)
            -- print(r)
            local idx = fromhex(r)
            -- print(idx)
            -- local idx = string.sub(mapdata[i],index,index)
            -- print(chars[num])
            cvdata = cvdata..chars[idx+1]
        end
        -- print("cvdata is "..cvdata)
        mapdata[i] = cvdata
        -- print(mapdata[i])
    end
    end
    -- map section

    rawmap = dumplua(mapdata)
    -- start out by making sure both sections exist, and are sized to max size


    local gfxexist, mapexist=false,false
    for k = 1, #out do
        if out[k] == "__gfx__" then
            gfxexist=true
        elseif out[k] == "__map__" then
            mapexist=true
        end
    end

    if not gfxexist then
        table.insert(out,"__gfx__")
    end
    if not mapexist then
        table.insert(out,"__map__")
    end

    for k,v in ipairs(out) do
        if out[k]=="__gfx__" or out[k]=="__map__" then
            local j=k+1
            while j<#out and not out[j]:match("__%a+__") do
                j=j+1
            end
            local emptyline=""
            for i=1,out[k]=="__gfx__" and 128 or 256 do
                emptyline=emptyline.."0"
            end
            for i=j,k+(out[k]=="__gfx__" and 128 or 32) do
                table.insert(out,i,emptyline)
            end
        end
    end
    local gfxstart, mapstart,labelstart
    for k = 1, #out do
        if out[k] == "__gfx__" then
            gfxstart = k
        elseif out[k] == "__map__" then
            mapstart = k
        elseif out[k] == "__label__" then
            labelstart = k
        end
    end

    -- print(labelstart)

    local gfxtable = {}
    for j = gfxstart, labelstart-1 do
        gfxtable[j] = out[j]
    end

    if not (mapstart and gfxstart) then
        error("uuuh")
    end

    for j = 0, 31 do
        local line = ""
        for i = 0, 127 do
            line = line .. tohex(map[i][j])
        end
        out[mapstart+j+1] = line
    end
    for j = 32, 63 do
        local line = ""
        for i = 0, 127 do
            line = line .. tohex_swapnibbles(map[i][j])
        end
        out[gfxstart+(j-32)*2+65] = string.sub(line, 1, 128)
        out[gfxstart+(j-32)*2+66] = string.sub(line, 129, 256)
    end

    
    --- here is the original patch
    if project.moresprites then
        for j = gfxstart, labelstart-1 do
            out[j] = gfxtable[j]
        end
    end

    local cartdata=table.concat(out, "\n")
    -- write to levels table without overwriting the code
    -- print(dumplua(mapdata))
    local dump = dumplua(mapdata):gsub("%%","%%%%")
    -- :gsub("\\13","\\r"):gsub("\\013","\\r"):gsub("\\\\r","\\\\13")
    -- removed this because it causes way too many edge cases


    --:gsub("\\?13","\\r")
    local builtdat = "--@begin\n";
    builtdat = builtdat.."levels="..dumplua(levels).."\n"
    builtdat = builtdat.."mapdata="..dump.."\n"
    builtdat = builtdat.."moresprites="..dumplua(project.moresprites).."\n"
    -- cartdata = cartdata:gsub("(%-%-@begin.*levels%s*=%s*){.-}(.*%-%-@end)","%1"..dumplua(levels).."%2")
    -- cartdata = cartdata:gsub("(%-%-@begin.*mapdata%s*=%s*){.-}(.*%-%-@end)","%1"..dump.."%2")

    cartdata = cartdata:gsub("%-%-@begin(.+)%-%-@end",builtdat.."\n--@end")
    --remove playtesting inject if one already exists:
    cartdata = cartdata:gsub("(%-%-@begin.*)local __init.-\n(.*%-%-@end)","%1".."%2")
    if app.playtesting and app.room then
        inject = "local __init = _init function _init() __init() begin_game() load_level("..app.room..") music(-1)"
        if app.playtesting == 2 then
            inject = inject.." max_djump=2"
        end
        inject = inject.." end"
        cartdata=cartdata:gsub("%-%-@end",inject.."\n--@end")
    end
    file = io.open(filename, "wb")
    file:write(cartdata)
    file:close()

    app.saveFileName = filename

    return true
end

--px9 stuff

-- function
--     px9_comp(x0,y0,w,h,dest,vget)

--     local dest0=dest
--     local bit=1
--     local byte=0

--     local cache = {}

--     local function vlist_val(l, val)
--         local v,i=l[1],1
--         while v!=val do
--             i+=1
--             v,l[i]=l[i],v
--         end
--         l[1]=val
--         return i
--     end

--     local cache,cache_bits=0,0
--     function putbit(bval)
--      cache=cache<<1|bval
--      cache_bits+=1
--         if cache_bits==8 then
--             add(dest,cache)
--             dest+=1
--             cache,cache_bits=0,0
--         end
--     end

--     function putval(val, bits)
--         for i=bits-1,0,-1 do
--             putbit(val>>i&1)
--         end
--     end

--     function putnum(val)
--         local bits = 0
--         repeat
--             bits += 1
--             local mx=(1<<bits)-1
--             local vv=min(val,mx)
--             putval(vv,bits)
--             val -= vv
--         until vv<mx
--     end


--     -- first_used

--     local el={}
--     local found={}
--     local highest=0
--     for y=y0,y0+h-1 do
--         for x=x0,x0+w-1 do
--             c=vget(x,y)
--             if not found[c] then
--                 found[c]=true
--                 add(el,c)
--                 highest=max(highest,c)
--             end
--         end
--     end

--     -- header

--     local bits=1
--     while highest >= 1<<bits do
--         bits+=1
--     end

--     putnum(w-1)
--     putnum(h-1)
--     putnum(bits-1)
--     putnum(#el-1)
--     for i=1,#el do
--         putval(el[i],bits)
--     end


--     -- data

--     local pr={} -- predictions

--     local dat={}

--     for y=y0,y0+h-1 do
--         for x=x0,x0+w-1 do
--             local v=vget(x,y)

--             local a=y>y0 and vget(x,y-1) or 0

--             -- create vlist if needed
--             local l=pr[a] or {unpack(el)}
--             pr[a]=l

--             -- add to vlist
--             add(dat,vlist_val(l,v))
           
--             -- and to running list
--             vlist_val(el, v)
--         end
--     end

--     -- write
--     -- store bit-0 as runtime len
--     -- start of each run

--     local nopredict
--     local pos=1

--     while pos <= #dat do
--         -- count length
--         local pos0=pos

--         if nopredict then
--             while dat[pos]!=1 and pos<=#dat do
--                 pos+=1
--             end
--         else
--             while dat[pos]==1 and pos<=#dat do
--                 pos+=1
--             end
--         end

--         local splen = pos-pos0
--         putnum(splen-1)

--         if nopredict then
--             -- values will all be >= 2
--             while pos0 < pos do
--                 putnum(dat[pos0]-2)
--                 pos0+=1
--             end
--         end

--         nopredict=not nopredict
--     end

--     return cache
-- end