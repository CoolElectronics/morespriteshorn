use mlua::prelude::*;
use rand::prelude::*;
use rustic_mountain_core::{
    objects::player::Player,
    structures::{Object, ObjectType, Vector},
    Celeste,
};

mod consts;

// Well, despite my warning, you decided to look into the playtest code.
// The text here cannot be classified as code. It is a monument to my sins.

// For a brief explanation, I had recently made a rust port for celeste classic.
// When I decided to try and add this feature to morespriteshorn, instead of adding an evercore comapatibility mode, I instead decided it would be easier to fake it by moving the player around screens
// this was a terrible idea, but i'm too far deep into it now to change my mind

static mut STATE: *mut State = std::ptr::null_mut::<State>();
// This first line alone violates the entire purpose of rust, but the borrow checker has forced my hand

use serde::Serialize;
#[derive(Serialize)]
struct State {
    celeste: Celeste,
    room: Vec<Vec<u8>>,
    offsetx: i32,
    offsety: i32,
}

fn start<'a>(lua: &'a Lua, _: ()) -> LuaResult<()> {
    unsafe {
        if !STATE.is_null() {
            return Ok(());
        }
        STATE = Box::leak(Box::new(State {
            celeste: Celeste::new(
                consts::MAPDATA.into(),
                consts::SPRITES.into(),
                consts::FLAGS.into(),
                "fontatlas".into(),
            ),
            room: vec![],
            offsetx: 0,
            offsety: 0,
        }));
        Ok(())
    }
}
fn update<'a>(lua: &'a Lua, _: ()) -> LuaResult<LuaValue<'a>> {
    // dbg!("asdasd");
    let state = unsafe { &mut (*STATE) };

    // if state.room.len() > 0 {
    //     load_tiles();
    // }
    for oref in &mut state.celeste.objects {
        let otmp = oref.clone();
        let mut obj = otmp.borrow_mut();
        if let ObjectType::Player(pref) = &mut obj.obj_type {
            let ptmp = pref.clone();
            let mut player = ptmp.borrow_mut();
            if obj.pos.x > 15.0 * 8.0 && state.offsetx < state.room.len() as i32 - 17 {
                let offset = 12.min(state.room.len() as i32 - state.offsetx - 17);
                do_offset(ivec(offset, 0), &mut player, &mut obj);
            }
            if obj.pos.x < 1.0 * 8.0 && state.offsetx > 0 {
                let offset = 12.min(state.offsetx);
                do_offset(ivec(-offset, 0), &mut player, &mut obj);
            }
            if obj.pos.y > 15.0 * 8.0 && state.offsety < state.room[0].len() as i32 - 17 {
                let offset = 12.min(state.room[0].len() as i32 - state.offsety - 17);
                do_offset(ivec(0, offset), &mut player, &mut obj);
            }
            if obj.pos.y < 1.0 * 8.0 && state.offsety > 0 {
                let offset = 12.min(state.offsety);
                do_offset(ivec(0, -offset), &mut player, &mut obj);
            }
        }
    }
    state.celeste.next_tick();
    draw(&mut state.celeste);

    lua.to_value(state)
}
fn ivec(x: i32, y: i32) -> Vector {
    Vector {
        x: x as f32,
        y: y as f32,
    }
}
fn do_offset(offset: Vector, player: &mut Player, playerobj: &mut Object) {
    let state = unsafe { &mut (*STATE) };
    for oref in &mut state.celeste.objects {
        if let Ok(mut obj) = oref.try_borrow_mut() {
            obj.pos.x -= offset.x * 8.0;
            obj.pos.y -= offset.y * 8.0;
        }
    }
    playerobj.pos.x -= offset.x * 8.0;
    playerobj.pos.y -= offset.y * 8.0;
    for node in &mut player.hair {
        node.x -= offset.x * 8.0;
        node.y -= offset.y * 8.0;
    }

    state.offsetx += offset.x as i32;
    state.offsety += offset.y as i32;
    load_tiles();
}
fn load_tiles() {
    let state = unsafe { &mut (*STATE) };
    for x in 0..16 {
        for y in 0..16 {
            state.celeste.mem.mset(
                x,
                y,
                state.room[state.offsetx as usize + x as usize]
                    [state.offsety as usize + y as usize],
            );
        }
    }
}
fn press<'a>(lua: &'a Lua, btn: usize) -> LuaResult<()> {
    let state = unsafe { &mut (*STATE) };

    state.celeste.mem.buttons[btn] = true;
    Ok(())
}
fn release<'a>(lua: &'a Lua, btn: usize) -> LuaResult<()> {
    let state = unsafe { &mut (*STATE) };
    state.celeste.mem.buttons[btn] = false;
    Ok(())
}
fn setRoom<'a>(lua: &'a Lua, map: LuaTable) -> LuaResult<()> {
    let state = unsafe { &mut (*STATE) };

    state
        .room
        .resize(map.clone().pairs::<usize, LuaTable>().count() + 1, vec![]);
    for t in map.pairs() {
        let (i, col): (usize, LuaTable) = t?;
        for t in col.pairs() {
            let (j, tile): (usize, u8) = t?;
            state.room[i].resize(j + 1, 0);
            state.room[i][j] = tile;
        }
    }
    load_tiles();
    Ok(())
}
fn resetLevel<'a>(lua: &'a Lua, _: ()) -> LuaResult<()> {
    let state = unsafe { &mut (*STATE) };
    state.offsetx = 0;
    state.offsety = 0;
    // let mut playerx = 0;
    // let mut playery = 0;

    for (i, col) in state.room.iter().enumerate() {
        for (j, tile) in col.iter().enumerate() {
            if *tile == 1 {
                // player spawn, start here
                // playerx = i;
                // playery = j;
                state.offsetx = (i as i32 / 16) * 16; //(i.max(16) as i32).min(state.room[0].len() as i32 - 17) % 16 * 16;
                state.offsety = (j as i32 / 16) * 16; //(j.max(16) as i32).min(state.room.len() as i32 - 17) % 16 * 16;
            }
        }
    }
    load_tiles();
    state.celeste.load_room(0, 0);
    Ok(())
}
pub fn draw(celeste: &mut Celeste) {
    celeste.shake = 0;
    if celeste.freeze > 0 {
        return;
    }
    for i in 0..128 * 128 {
        celeste.mem.graphics[i] = 0; // (i % 15) as u8;
    }
    //clearing screen
    // TODO:
    // title screen
    // reset palette
    celeste.mem.pal(8, 8);
    // for cloud in &mut celeste.clouds {
    //     cloud.x += cloud.spd;
    //     celeste.mem.rectfill(
    //         cloud.x,
    //         cloud.y,
    //         cloud.x + cloud.w,
    //         cloud.y + 16 - (cloud.w as f32 * 0.1875) as i32,
    //         1,
    //     );
    //     if cloud.x > 128 {
    //         cloud.x = -cloud.w;
    //         cloud.y = celeste.mem.rng.gen_range(0..120);
    //     }
    // }

    for i in 0..celeste.objects.len() {
        let v = celeste.objects[i].clone();
        v.borrow_mut().draw(celeste);
    }

    for particle in &mut celeste.particles {
        particle.x += particle.spd;
        particle.y += particle.off.to_degrees().sin();

        celeste.mem.rectfill(
            particle.x as i32,
            particle.y as i32,
            (particle.x + particle.s) as i32,
            (particle.y + particle.s) as i32,
            particle.c,
        );
        if particle.x > 132.0 {
            particle.x = -4.0;
            particle.y = celeste.mem.rng.gen_range(0.0..128.0);
        }
    }
    for particle in &mut celeste.dead_particles {
        particle.x += particle.dx;
        particle.y += particle.dy;

        particle.t -= 0.2;

        if particle.t > 0.0 {
            celeste.mem.rectfill(
                (particle.x - particle.t) as i32,
                (particle.y - particle.t) as i32,
                (particle.x + particle.t) as i32,
                (particle.y + particle.t) as i32,
                14 + ((particle.t * 5.0) % 2.0) as u8,
            );
        }
    }
    celeste.dead_particles.retain(|f| f.t > 0.0);
}
// #[derive(mlua::S/)]
// struct Cel(Celeste);

#[mlua::lua_module]
fn librustic(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    exports.set("update", lua.create_function(update)?)?;
    exports.set("start", lua.create_function(start)?)?;
    exports.set("press", lua.create_function(press)?)?;
    exports.set("release", lua.create_function(release)?)?;
    exports.set("setRoom", lua.create_function(setRoom)?)?;
    exports.set("resetLevel", lua.create_function(resetLevel)?)?;

    Ok(exports)
}
