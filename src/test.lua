-- awful, i know. still helps a little bit tho

function runtest()
    local filename = filedialog.open()
    if filename then
        openPico8(filename)

        -- remember to fix empty rooms + >256 serialization
        project.rooms = {};
        print("does anything at all work test")
        local room = nroom(1, 1)
        table.insert(project.rooms, room)
        loadcycle(filename)

        project.rooms = {};
        print("empty room test")
        local room = nroom(16, 16)
        table.insert(project.rooms, room)
        loadcycle(filename)

        project.rooms = {};
        print("empty map test")
        local room = nroom(16*4, 16*4)
        table.insert(project.rooms, room)
        loadcycle(filename)

        project.rooms = {};
        print("alltiles room test")
        local room = nroom(16, 16)

        local indx = 0
        for x=0,15 do
            for y=0,15 do
                room.data[y][x] = indx
                indx = indx + 1
            end
        end

        table.insert(project.rooms, room)
        loadcycle(filename)

        project.rooms = {};
        print("alltiles map test")
        local room = nroom(16*4, 16*4)

        local indx = 0
        for x=0,16*4-1 do
            for y=0,16*4-1 do
                room.data[y][x] = indx % 256
                indx = indx + 1
            end
        end
        table.insert(project.rooms, room)
        loadcycle(filename)

        math.randomseed(os.time())

        print("testing every tile against every other tile")
        for i=0,255 do
            for i2=0,255 do
                project.rooms = {};
                local room = nroom(4,1)
                room.data[0][0] = math.random(0,255)
                room.data[1][0] = i
                room.data[2][0] = i2
                room.data[3][0] = math.random(0,255)
                table.insert(project.rooms, room)
                loadcycle(filename)
 
            end
            print(i.."/255")
        end
        print("testing every tile against every other tile against every other tile")
        for i=0,255 do
            for i2=0,255 do
                for i3=0,255 do
                    project.rooms = {};
                    local room = nroom(5,1)

                    room.data[0][0] = math.random(0,255)
                    room.data[1][0] = i
                    room.data[2][0] = i2
                    room.data[3][0] = i3
                    room.data[4][0] = math.random(0,255)
                    table.insert(project.rooms, room)
                    loadcycle(filename)
                end
            end
            print(i.."/255")
        end


        for i=0,255,1 do 
            project.rooms = {};
            print("random map test")
            local room = nroom(16, 16)
            for x=0,15 do
                for y=0,15 do
                    room.data[y][x] = math.random(0,255)
                end
            end
            table.insert(project.rooms, room)
            loadcycle(filename)
        end

        print("all tests passed. there could still be issues but that's not really my problem")
    end
end
function nroom(w,h)
    local room = newRoom(0, 0, w, h)
    room.title = ""
    room.customexit = false
    room.top = "nil"
    room.right = "nil"
    room.bottom = "nil"
    room.left = "nil"
    return room
end


function loadcycle(filename)
    savePico8(filename)
    local beforesave = rawmap
    loadpico8(filename)
    if beforesave ~= rawmap then
        print("FAILED TEST")

        for i=1,#beforesave do
            if (string.sub(beforesave,i,i) ~= string.sub(rawmap,i,i)) then
                print("err at position "..i)
                break
            end
        end

        local beforef = io.open("before.wtf","wb")
        local afterf = io.open("after.wtf","wb")
        beforef:write(beforesave)
        afterf:write(rawmap)
        beforef:close()
        afterf:close()
        os.exit()
        -- love.event.quit() isn't an instant exit 
    end

end

function equals(o1, o2, ignore_mt)
    if o1 == o2 then return true end
    local o1Type = type(o1)
    local o2Type = type(o2)
    if o1Type ~= o2Type then return false end
    if o1Type ~= 'table' then return false end

    if not ignore_mt then
        local mt1 = getmetatable(o1)
        if mt1 and mt1.__eq then
            --compare using built in method
            return o1 == o2
        end
    end

    local keySet = {}

    for key1, value1 in pairs(o1) do
        local value2 = o2[key1]
        if value2 == nil or equals(value1, value2, ignore_mt) == false then
            return false
        end
        keySet[key1] = true
    end

    for key2, _ in pairs(o2) do
        if not keySet[key2] then return false end
    end
    return true
end