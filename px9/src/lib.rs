use mlua::prelude::*;

fn decompress<'a>(lua: &'a Lua, lsource: LuaTable) -> LuaResult<LuaTable<'a>> {
    let mut source = vec![];

    for i in 1..lsource.len()? {
        source.push(lsource.get(i)?);
    }
    dbg!(&source);
    let mut dest: Vec<i32> = vec![0; 128 * 64];

    let mut destidx: usize = 0;

    let mut cache: i32 = 0;
    let mut cache_bits: i32 = 0;

    //wtf lol
    let w = gnp(&mut source, &mut destidx, &mut cache, &mut cache_bits, 1);
    let h_1 = gnp(&mut source, &mut destidx, &mut cache, &mut cache_bits, 0);
    let eb = gnp(&mut source, &mut destidx, &mut cache, &mut cache_bits, 1);
    let mut el: Vec<i32> = vec![];
    let mut pr: Vec<Option<Vec<i32>>> = vec![None; 128];
    // let mut x = 0;
    // let mut y = 0;
    let mut splen = 0;
    let mut predict: bool = false;

    // may not be 1?
    for i in 0..gnp(&mut source, &mut destidx, &mut cache, &mut cache_bits, 1) {
        el.push(getval(
            &mut source,
            &mut destidx,
            &mut cache,
            &mut cache_bits,
            eb,
        ));
    }
    dbg!(&h_1);
    dbg!(w);
    for y in 0..h_1 + 1 {
        dbg!("got here");
        for x in 0..w {
            splen -= 1;
            if splen < 1 {
                splen = gnp(&mut source, &mut destidx, &mut cache, &mut cache_bits, 1);
                predict = !predict;
            }
            let mut a = 0;
            if y - 1 > 0 {
                a = vget(&source, x, y - 1);
            }

            let mut l = pr[a as usize].clone().unwrap_or(el.clone()).clone();
            pr[a as usize] = Some(l.clone());
            let v = l[if predict {
                1
            } else {
                gnp(&mut source, &mut destidx, &mut cache, &mut cache_bits, 2)
            } as usize
                - 1];

            vlist_val(&mut l, v);
            vlist_val(&mut el, v);
            dbg!("trying to set");
            vset(&mut dest, x, y, v);
        }
    }
    // let

    //     local
    //     w,h_1,      -- w,h-1
    //     eb,el,pr,
    //     x,y,
    //     splen,
    //     predict
    //     =
    //     gnp"1",gnp"0",
    //     gnp"1",{},{},
    //     0,0,
    //     0
    //     --,nil

    // for i=1,gnp"1" do
    //     add(el,getval(eb))
    // end
    // for y=y0,y0+h_1 do
    //     for x=x0,x0+w-1 do
    //         splen-=1

    //         if(splen<1) then
    //             splen,predict=gnp"1",not predict
    //         end

    //         local a=y>y0 and vget(x,y-1) or 0

    //         -- create vlist if needed
    //         local l=pr[a] or {unpack(el)}
    //         pr[a]=l

    //         -- grab index from stream
    //         -- iff predicted, always 1

    //         local v=l[predict and 1 or gnp"2"]

    //         -- update predictions
    //         vlist_val(l, v)
    //         vlist_val(el, v)

    //         -- set
    //         vset(x,y,v)
    //     end
    // end
    dbg!(&dest);
    let restable = lua.create_table()?;
    for (i, v) in dest.iter().enumerate() {
        restable.set(i + 1, v.clone())?;
    }

    Ok(restable)
}

fn vget(source: &Vec<i32>, x: i32, y: i32) -> i32 {
    dbg!(y);
    if y > 63 {
        panic!("wat");
    }
    source[y as usize * 128 + x as usize]
}
fn vset(dest: &mut Vec<i32>, x: i32, y: i32, v: i32) {
    dest[y as usize * 128 + x as usize] = v;
}

fn gnp(
    source: &mut Vec<i32>,
    destidx: &mut usize,
    cache: &mut i32,
    cache_bits: &mut i32,
    num: i32,
) -> i32 {
    let mut n = num;
    let mut bits = 0;
    let mut vv = 0;
    loop {
        bits += 1;
        vv = getval(source, destidx, cache, cache_bits, bits);
        n += vv;
        if vv < (1 << bits) - 1 {
            return n;
        }
    }
}
fn getval(
    source: &mut Vec<i32>,
    destidx: &mut usize,
    cache: &mut i32,
    cache_bits: &mut i32,
    bits: i32,
) -> i32 {
    if *cache_bits < 8 {
        *cache_bits += 8;
        *cache += source[*destidx] >> *cache_bits;
        *destidx += 1;
    }
    *cache <<= bits;
    let val = *cache & 0xffff;
    *cache ^= val;
    *cache_bits -= bits;
    val
}
// fn put_bit(cache: &mut i32, cache_bits: &mut i32, bval: i32) {
//     *cache = *cache << 1 | bval;
//     *cache_bits += 1;
//     if *cache_bits == 8 {
//         poke?
//         *dest +=1;
//         *cache = 0;
//         *cache_bits = 0;
//     }
// }
fn vlist_val(list: &mut Vec<i32>, value: i32) -> usize {
    let mut v = list[0];
    let mut i = 0;
    while v != value {
        i += 1;
        (v, list[i]) = (list[i], v);
    }
    list[i] = value;
    return i;
}

#[mlua::lua_module]
fn libpx9(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    exports.set("decompress", lua.create_function(decompress)?)?;
    Ok(exports)
}
