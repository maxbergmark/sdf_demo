struct Uniforms {
    mouse: vec2<f32>,
    width: f32,
    height: f32,
    from_index: u32,
    to_index: u32,
    blend: f32,
    a: f32,
    rendering_method_from: u32,
    rendering_method_to: u32,
    rendering_blend: f32,
    t: f32,
    frame_start: f32,
    last_frame_start: f32,
    show_distance: u32,
    _pad: f32,
}

@group(0) @binding(0)
var<uniform> uniforms: Uniforms;

struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) uv: vec2<f32>,
};

@vertex
fn vs_main(@builtin(vertex_index) vertex_index: u32) -> VertexOutput {
    var positions = array<vec2<f32>, 6>(
        vec2<f32>(-1.0, -1.0),
        vec2<f32>(1.0, -1.0),
        vec2<f32>(-1.0, 1.0),
        vec2<f32>(-1.0, 1.0),
        vec2<f32>(1.0, -1.0),
        vec2<f32>(1.0, 1.0)
    );

    let pos = positions[vertex_index];
    var out: VertexOutput;
    out.position = vec4<f32>(pos, 0.0, 1.0);
    out.uv = pos * 0.5 + vec2<f32>(0.5, 0.5);
    out.uv.y = 1.0 - out.uv.y;
    return out;
}

struct FragInput {
    @location(0) uv: vec2<f32>,
};

struct Surface {
    sdf: SdfGradient,
    color: vec4<f32>,
}

struct SdfGradient {
    d: f32,
    gradient: vec2<f32>,
}

// 255, 102, 0
const EQT_ORANGE = vec4<f32>(1.0, 0.3961, 0.0, 1.0);
// #d89048
const COLOR_OUTSIDE = vec4<f32>(0.8471, 0.5647, 0.2824, 1.0);
// ##c6f6ff
const COLOR_INSIDE = vec4<f32>(0.7065, 0.9208, 1.0, 1.0);
const WHITE = vec4<f32>(1.0, 1.0, 1.0, 1.0);
const GRAY = vec4<f32>(0.5, 0.5, 0.5, 1.0);
const PI = 3.14159265358979323846;


@fragment
fn fs_main(input: FragInput) -> @location(0) vec4<f32> {
    let aspect_ratio = uniforms.width / uniforms.height;
    var p = input.uv * 2.0 - vec2<f32>(1.0, 1.0);
    p.x *= aspect_ratio;
    let surface = sdf(p);
    var color = colorize(p, surface);
    if uniforms.show_distance == 1 {
        let s = sdf(uniforms.mouse).sdf;
        let px = 2.0 / uniforms.height;
        let dist = length(p - uniforms.mouse);
        let diff = dist - abs(s.d);
        let ring_color = mix_srgb4(color, WHITE, 0.3);
        color = mix(color, ring_color, smoothstep(1.5*px,0.0,abs(diff)-0.002));
        color = mix(color, WHITE, smoothstep(1.5*px,0.0,abs(dist)-0.005));
    }

    return vec4<f32>(color.rgb, 1.0);
}

fn colorize(p: vec2<f32>, surface: Surface) -> vec4<f32> {
    let color_from = colorize_select(p, surface, uniforms.rendering_method_from);
    let color_to = colorize_select(p, surface, uniforms.rendering_method_to);
    return mix(color_from, color_to, uniforms.rendering_blend);
}

fn colorize_select(p: vec2<f32>, surface: Surface, method: u32) -> vec4<f32> {
    if method == 0 {
        return distance(surface.sdf.d);
    }
    if method == 1 {
        return gradient(surface.sdf);
    }
    if method == 2 {
        return outline(surface);
    }
    if method == 3 {
        return fill(surface);
    }
    if method == 4 {
        return shadow(p, surface);
    }
    if method == 5 {
        return inside_glow(surface);
    }
    if method == 6 {
        return outside_glow(surface);
    }
    return vec4<f32>(0.0, 0.0, 0.0, 1.0);
}

fn distance(d: f32) -> vec4<f32> {
    let px = 2.0 / uniforms.height;
    var col = select(vec3<f32>(0.9,0.6,0.3), vec3<f32>(0.65,0.85,1.0), d<0.0);
	col *= 1.0 - exp2(-12.0*abs(d));
	col *= 0.8 + 0.2*cos(120.0*d);
	col = mix( col, vec3<f32>(1.0), smoothstep(1.5*px,0.0,abs(d)-0.002) );
    return vec4<f32>(col, 1.0);
}

fn gradient(sdf: SdfGradient) -> vec4<f32> {
    let px = 2.0 / uniforms.height;
    let d = sdf.d;
    let g = sdf.gradient;
    var col = select(vec3<f32>(0.4, 0.7, 0.85), vec3<f32>(0.9, 0.6, 0.3), d > 0.0);
    col *= 1.0 + vec3<f32>(0.5 * g, 0.0);
    // col = vec3<f32>(0.5 + 0.5 * g, 1.0, 1.0);
    col *= 1.0 - 0.7 * exp(-12.0 * abs(d));
    col *= 0.85 + 0.15 * cos(120.0 * d);
    // col = mix(col, vec3<f32>(1.0), 1.0 - smoothstep(0.0, 0.01, abs(d)));
	col = mix( col, vec3<f32>(1.0), smoothstep(1.5*px,0.0,abs(d)-0.002) );
    return vec4<f32>(col, 1.0);
}

fn outline(surface: Surface) -> vec4<f32> {
    let d = surface.sdf.d;
    let px = 2.0 / uniforms.height;
	let col = mix( vec3<f32>(0.0), surface.color.rgb, smoothstep(1.5*px,0.0,abs(d)-0.002) );
    return vec4<f32>(col, 1.0);
}

fn fill(surface: Surface) -> vec4<f32> {
    let d = surface.sdf.d;
    let px = 2.0 / uniforms.height;
	let col = mix( vec3<f32>(0), surface.color.rgb, smoothstep(1.5*px,0.0,d-0.002) );
    return vec4<f32>(col, 1.0);
}

fn inside_glow(surface: Surface) -> vec4<f32> {
    let px = 2.0 / uniforms.height;
    let d = surface.sdf.d;
    let decay = exp(-d*d * 50.0);
	let col = mix( vec3<f32>(0), to_linear(surface.color.rgb), decay * smoothstep(1.5*px,0.0,d-0.002) );
    return vec4<f32>(to_srgb(col), 1.0);
}

fn outside_glow(surface: Surface) -> vec4<f32> {
    let px = 2.0 / uniforms.height;
    let d = surface.sdf.d;
    let decay = exp(-d*d * 500.0);
	let bg = mix( vec3<f32>(0), to_linear(surface.color.rgb), decay * smoothstep(0.0,1.5*px,d+0.002) );
    let col = mix(bg * 0.5, to_linear(surface.color.rgb), smoothstep(1.5*px,0.0,d-0.002));
    return vec4<f32>(to_srgb(col), 1.0);
}

fn shadow(p: vec2<f32>, surface: Surface) -> vec4<f32> {
    let px = 2.0 / uniforms.height;
    let d = surface.sdf.d;
    let dir = normalize(vec2<f32>(-1.0, -1.0));
    let shadow = soft_shadow(p, dir, 1.0, 0.05);
    let y = p.y + 0.5;
    let bg = mix(vec3<f32>(0.95, 0.94, 0.92), vec3<f32>(0.80, 0.79, 0.82), y);
    let base_lin = to_linear(bg);
    let ambient = 0.35;                                   // shadows never go below this
    let shade = ambient + (1.0 - ambient) * shadow;      // shadow in [0,1]
    let shadow_tint = vec3<f32>(0.62, 0.60, 0.66);         // cool, desaturated
    let background = base_lin * mix(shadow_tint, vec3<f32>(1.0), shade);
    let col = mix( background, to_linear(surface.color.rgb), smoothstep(1.5*px,0.0,d-0.002) );
    return vec4<f32>(to_srgb(col), 1.0);
}

fn soft_shadow(origin: vec2<f32>, dir: vec2<f32>, k: f32, max_t: f32) -> f32 {
    var res = 1.0;
    var t = 0.05;
    var ph = 1e20;
    for (var i = 0; i < 12; i = i + 1) {
        let h = sdf(origin + dir * t).sdf.d;
        if (h < 0.001) { return 0.0; }
        let y = h * h / (2.0 * ph);
        let dd = sqrt(max(h * h - y * y, 0.0));
        res = min(res, k * dd / max(0.0001, t - y));
        ph = h;
        t += h;
        if (res < 0.005 || t > max_t) { break; }   // early exit
    }
    return clamp(res, 0.0, 1.0);
}

fn colorize2(d: f32) -> vec4<f32> {
    let phase = sin(abs(d) * 200.0) * 0.3 + 0.7;
    let decay = 1.0 - exp(-abs(d) * 10.0);
    let aa = fwidth(d);

    let base = select(COLOR_OUTSIDE, COLOR_INSIDE, d < 0.0) * phase * decay;

    let outline = smoothstep(-0.01 - aa * 0.5, -0.01 + aa * 0.5, d)
                * smoothstep( 0.01 + aa * 0.5,  0.01 - aa * 0.5, d);

    return mix(base, WHITE, outline);
}

const LARGE = 1.0;

fn sdf(p: vec2<f32>) -> Surface {
    let from_sdf = sdf_select(p, uniforms.from_index, uniforms.last_frame_start);
    let to_sdf = sdf_select(p, uniforms.to_index, uniforms.frame_start);

    // A retreats as t→1, B emerges
    let t = uniforms.blend;
    let g = mix(from_sdf.sdf.gradient, to_sdf.sdf.gradient, t);
    let d = mix(from_sdf.sdf.d, to_sdf.sdf.d, t);
    let s = SdfGradient(d, g);
    let color = mix_srgb4(from_sdf.color, to_sdf.color, uniforms.blend);

    return Surface(s, color);
}

fn sdf_select(p: vec2<f32>, index: u32, frame_start: f32) -> Surface {
    // var d: f32;
    // var color: vec4<f32> = EQT_ORANGE;
    var surface: Surface;
    surface.color = EQT_ORANGE;
    if index == 0 {
        let t = uniforms.t - frame_start;
        let a = uniforms.a;
        let offset = 0.5 * a * sin(1.0 * t);
        let p2 = translate(p, vec2<f32>(offset, 0));
        surface.sdf = circle(p2, 0.5);
    }
    if index == 1 {
        surface.sdf = rectangle_gradient(p, vec2<f32>(0.5, 0.4));
    }
    if index == 2 {
        let t = sin(uniforms.t * 2.0) * 0.5 + 0.5;
        let w = 0.1 * t; 
        let a = uniforms.a;
        let size = vec2<f32>(0.5 - w * a , 0.4 - w * a);
        surface.sdf = smooth_gradient(rectangle_gradient(p, size), w);
    }
    if index == 3 {
        let t = sin(uniforms.t * 2.0) * 0.5 + 0.5;
        let w = 20.0 / t;
        let size = vec2<f32>(0.4, 0.3);
        var sdg = rectangle_gradient(p, size);
        sdg.d -= 0.1;
        surface.sdf = sdg;
        surface.color = sunlight(with_color(sdg, EQT_ORANGE), w);
    }
    if index == 4 {
        var s1 = with_color(rounded_rectangle_gradient(p, vec2<f32>(0.5, 0.4), 0.1), EQT_ORANGE);
        let s2 = with_color(circle(p - uniforms.mouse, 0.3), WHITE);
        let s = smin_surface(s1, s2, uniforms.a);
        surface.sdf = s.sdf;
        surface.color = sunlight(s, 30.0);
    }
    if index == 5 {
        let d1 = rectangle(p, vec2<f32>(0.5, 0.4));
        let d2 = circle(p - uniforms.mouse, 0.3).d;
        let k = 0.2;
        let res = smin_blend(d1, d2, k);
        surface.sdf.d = res.x;
        let t = 1.0 - res.y;                  // h=1 when d1(rect) is closer
        surface.color = mix(EQT_ORANGE, WHITE, t);
    }
    if index == 6 {
        let t = uniforms.t*0.2;
        let c1 = vec4<f32>(1.0, 0.5, 0.0, 1.0);
        let c2 = vec4<f32>(0.0, 1.0, 1.0, 1.0);
        let c3 = vec4<f32>(1.0, 0.0, 1.0, 1.0);
        let c4 = vec4<f32>(1.0, 1.0, 0.0, 1.0);
        let d1 = circle(p - 0.3*vec2<f32>(sin(t*2), cos(t*5)), 0.3);
        let d2 = circle(p - 0.4*vec2<f32>(sin(t*7), cos(t*3)), 0.4);
        let d3 = circle(p - 0.5*vec2<f32>(sin(t*3.5), cos(t*6)), 0.3);
        let d4 = circle(p - 0.6*vec2<f32>(sin(t*4), cos(t*7)), 0.4);
        let k = 0.1 + 0.5 * uniforms.a;

        let s1 = Surface(d1, c1);
        let s2 = Surface(d2, c2);
        let s3 = Surface(d3, c3);
        let s4 = Surface(d4, c4);
        let s = smin_surface(s1, smin_surface(s2, smin_surface(s3, s4, k), k), k);
        let w = 3.33 / max(uniforms.a, 1e-6);
        let final_color = sunlight(s, w);
        surface.sdf = s.sdf;
        surface.color = final_color;
    }
    if index == 7 {
        let sdg = smooth_gradient(rectangle_gradient(repeat(p, vec2<f32>(0.5, 0.4)*0.35), vec2<f32>(0.4, 0.3)*0.1), 0.02);
        let final_color = sunlight(with_color(sdg, EQT_ORANGE), 50.0);
        surface.sdf = sdg;
        surface.color = final_color;
    }
    if index == 8 {
        let d1 = smooth_gradient(rectangle_gradient(repeat(p, vec2<f32>(0.5, 0.4)*0.35), vec2<f32>(0.4, 0.3)*0.1), 0.02);
        // var d1 = rectangle_gradient(p, vec2<f32>(0.5, 0.4));
        let d2 = circle(p - uniforms.mouse, 0.5);
        var sdg = ssub_gradient(d1, d2, 0.01);
        surface.sdf = sdg;
        surface.color = sunlight(with_color(sdg, EQT_ORANGE), 30.0);
    }
    if index == 9 {
        let x_offset = array<f32, 10>(15.105762016284807, 66.75213939380032, 24.576142195051297, 78.05102918739071, 42.735442706267754, 51.001237867972385, 72.34326969104954, 7.327654375380755, 90.40682406109272, 35.71276539571075);
        let y_offset = array<f32, 10>(53.74317862550531, 85.23981992472287, 29.703435993625384, 82.08447970975581, 35.07665993737946, 70.97812114584, 5.330707208960284, 36.0846691221548, 19.959420213543023, 95.6516270747098);
        let angles = array<f32, 10>(4.641453081142971, 4.492214232092462, 5.970784844929799, 6.233110050449939, 3.2447643399115638, 0.05582118483421819, 3.4631994369022845, 4.49588529220744, 0.4456076730154957, 4.772053382359597);
        let t = uniforms.t;
        let d1 = smooth_gradient(rectangle_gradient(repeat(p, vec2<f32>(0.5, 0.4)*0.35), vec2<f32>(0.4, 0.3)*0.1), 0.02);
        // var d1 = rectangle_gradient(p, vec2<f32>(0.5, 0.4));
        let d2 = circle(p - uniforms.mouse, 0.5);
        var sdg = sintersect_gradient(d1, d2, 0.01);
        // sdg.d += sin(t * 2.0 + p.x * 10.0 + p.y * 20.0) * 0.01 * uniforms.a;
        var factor = 0.005;
        var freq = 1.0;
        for (var i = 0; i < 10; i = i + 1) {
            let xf = x_offset[i] - 50.0;
            let yf = y_offset[i] - 50.0;
            let p2 = rotate(p, angles[i]);
            sdg.d += sin(t * freq + xf * p2.x * freq + yf * p2.y * freq) * factor * uniforms.a;
            factor *= 0.8;
            freq *= 1.25;
        }
        surface.sdf = sdg;
        surface.color = sunlight(with_color(sdg, EQT_ORANGE), 30.0);
    }
    // if index == 10 {
    //     let t = uniforms.t;
    //     var sdg = smooth_gradient(rectangle_gradient(repeat_bounded(p, vec2<f32>(0.5, 0.4)*0.35, vec2<f32>(-3.0, -2.0), vec2<f32>(3.0, 2.0)), vec2<f32>(0.4, 0.3)*0.1), 0.02);
    //     sdg.d += sin(t * 2.0 + p.x * 10.0 + p.y * 20.0) * 0.01 * uniforms.a;
    //     let final_color = sunlight(with_color(sdg, EQT_ORANGE), 50.0);
    //     surface.sdf = sdg;
    //     surface.color = final_color;
    // }
    if index == 11 {
        let idx = repeat_idx(p, 12.0);
        var sdg = smooth_gradient(heart_gradient(repeat_round(p, 12.0) + vec2<f32>(0.0, -0.8), 0.125), 0.01);
        sdg = unfold_gradient(p, sdg, 12.0);
        surface.sdf = sdg;
        surface.color = sunlight(with_color(sdg, EQT_ORANGE), 30.0);
    }
    if index == 12 {
        let p_rot = rotate(p, uniforms.t * 0.2);
        let p_rot2 = rotate(p, -uniforms.t * 0.1);

        var heart = smooth_gradient(heart_gradient(repeat_round(p, 12.0)+ vec2<f32>(0.0, -0.8), 0.125), 0.01);
        heart = unfold_gradient(p, heart, 12.0);
        let heart_s = Surface(heart, EQT_ORANGE);

        var star = smooth_gradient(star_gradient(repeat_round(p_rot, 16.0) + vec2<f32>(0.0, -1.1), 0.125), 0.0);
        star = unfold_gradient(p_rot, star, 16.0);
        star.gradient = rotate(star.gradient, uniforms.t * 0.2);
        let star_s = Surface(star, EQT_ORANGE);

        var heart2 = smooth_gradient(heart_gradient(repeat_round(p_rot2, 20.0) + vec2<f32>(0.0, -1.3), 0.125), 0.01);
        heart2 = unfold_gradient(p_rot2, heart2, 20.0);
        heart2.gradient = rotate(heart2.gradient, -uniforms.t * 0.1);
        let heart2_s = Surface(heart2, EQT_ORANGE);

        let s = smin_surface(smin_surface(heart_s, star_s, 0.0), heart2_s, 0.0);
        surface.sdf = s.sdf;
        surface.color = sunlight(s, 30.0);
    }
    if index == 13 {
        let s = hearts_and_stars(p);
        surface.sdf = s.sdf;
        surface.color = sunlight(s, 30.0);
    }
    if index == 14 {
        let sdg = eqt_sdf_gradient(p);
        surface.sdf = sdg;
        surface.color = sunlight(with_color(sdg, EQT_ORANGE), 30.0);
    }
    if index == 15 {
        let s = eqt_logo_sdf(p);
        surface.sdf = s.sdf;
        surface.color = sunlight(s, 30.0);
    }
    if index == 16 {
        let t = uniforms.t - frame_start;
        let scale = 1.0 + smoothstep(0.0, 1.0, t - 0.5);
        let offset = 1.0 - smoothstep(0.0, 1.0, t - 1.0);
        var logo = eqt_logo_sdf(p*scale);
        logo.sdf.d /= scale;
        var background = hearts_and_stars(p);
        background.sdf.d += offset;
        let s = smin_surface(logo, background, 0.0);
        surface.sdf = s.sdf;
        surface.color = sunlight(s, 30.0);
    }
    if index == 17 {
        let scale = 2.0;
        var logo = eqt_logo_sdf(p*scale);
        logo.sdf.d /= scale;
        var background = hearts_and_stars(p);
        let s = smin_surface(logo, background, 0.0);
        surface.sdf = s.sdf;
        surface.color = sunlight(s, 30.0);
    }
    return surface;
}

fn sun_intensity2(sdg: SdfGradient, w: f32) -> f32 {
    let a = acos(max(0.0, 1+sdg.d*w));
    let n = vec3(cos(a)*sdg.gradient, sin(a));
    let sun_direction = normalize(vec3<f32>(-1.0, -1.0, 1.0));
    let intensity = max(0.0, dot(n, sun_direction)) * 1 + 0.385;
    return intensity;
}

fn sunlight(surface: Surface, w: f32) -> vec4<f32> {
    let intensity = sun_intensity(surface.sdf, w);
    return vec4<f32>(to_srgb(to_linear(surface.color.rgb) * intensity), 1.0);
}

fn sun_intensity(sdg: SdfGradient, w: f32) -> f32 {
    let a = acos(max(0.0, 1.0 + sdg.d * w));
    let n = vec3<f32>(cos(a) * sdg.gradient, sin(a));
    let sun_direction = normalize(vec3<f32>(-1.0, -1.0, 1.0));
    let view = vec3<f32>(0, 0, 1);
    let half_vec = normalize(sun_direction + view);
    let diffuse  = max(0.0, dot(n, sun_direction));
    let spec     = pow(max(dot(n, half_vec), 0.0), 32.0);
    let fresnel  = pow(1.0 - max(dot(n, view), 0.0), 5.0);
    return 0.38452 + diffuse + spec * 0.6 + fresnel * 0.4;
}

fn smooth_sdf(d: f32, r: f32) -> f32 {
    return d - r;
}

fn smooth_gradient(g: SdfGradient, r: f32) -> SdfGradient {
    return SdfGradient(smooth_sdf(g.d, r), g.gradient);
}

fn with_color(s: SdfGradient, color: vec4<f32>) -> Surface {
    return Surface(s, color);
}

fn smin_blend(a: f32, b: f32, k: f32) -> vec2<f32> {
    let h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    let d = mix(b, a, h) - k * h * (1.0 - h);
    return vec2<f32>(d, h);
}

fn smin_gradient(a: SdfGradient, b: SdfGradient, k: f32) -> SdfGradient {
    let h = clamp(0.5 + 0.5 * (b.d - a.d) / k, 0.0, 1.0);
    let d = mix(b.d, a.d, h) - k * h * (1.0 - h);
    let gradient = mix(b.gradient, a.gradient, h);
    return SdfGradient(d, gradient);
}

fn ssub_gradient(a: SdfGradient, b: SdfGradient, k: f32) -> SdfGradient {
    return invert_sdf(smin_gradient(invert_sdf(a), b, k));
}

fn sintersect_gradient(a: SdfGradient, b: SdfGradient, k: f32) -> SdfGradient {
    return invert_sdf(smin_gradient(invert_sdf(a), invert_sdf(b), k));
}

fn invert_sdf(s: SdfGradient) -> SdfGradient {
    return SdfGradient(
        s.d * -1,
        s.gradient * -1,
    );
}

fn smin_surface(a: Surface, b: Surface, k: f32) -> Surface {
    let h = clamp(0.5 + 0.5 * (b.sdf.d - a.sdf.d) / k, 0.0, 1.0);
    let sdf = smin_gradient(a.sdf, b.sdf, k);
    let color = to_srgb4(mix(to_linear4(b.color), to_linear4(a.color), h));
    return Surface(sdf, color);
}

fn smooth_add( a: f32, b: f32, k: f32 ) -> f32 {
    let h = max(4.0*k-abs(a-b),0.0);
    return min(a, b) - h*h/(k*16.0);
}

fn smooth_subtract( a: f32, b: f32, k: f32 ) -> f32 {
    return -smooth_add(-a, b, k);
}

fn rotate(p: vec2<f32>, angle: f32) -> vec2<f32> {
    let c = cos(angle);
    let s = sin(angle);
    return mat2x2<f32>(c, s, -s, c) * p;
}

fn repeat(p: vec2<f32>, size: vec2<f32>) -> vec2<f32> {
    return p - size * round(p / size);
}

fn repeat_bounded(p: vec2<f32>, s: vec2<f32>, low: vec2<f32>, high: vec2<f32>) -> vec2<f32> {
    return p - s * clamp(round(p / s), low, high);
}

fn repeat_round(p: vec2<f32>, n: f32) -> vec2<f32> {
    let angle = 2.0 * PI / n;
    let a = atan2(p.y, p.x);
    let a_fold = a - angle * round(a / angle);
    let r = length(p);
    return vec2<f32>(r * a_fold, r);
}

fn repeat_idx(p: vec2<f32>, n: f32) -> f32 {
    let angle = 2.0 * PI / n;
    let a = atan2(p.y, p.x);
    return (n + round(a / angle)) % n;
}

fn unfold_gradient(p: vec2<f32>, s_in: SdfGradient, n: f32) -> SdfGradient {
    var s = s_in;
    let idx = repeat_idx(p, n);
    s.gradient = rotate(s.gradient, -idx * 2.0 * PI / n);
    return s;
}



fn hearts_and_stars(p: vec2<f32>) -> Surface {
    let t = uniforms.t;
    let p2 = p * 1.0;
    let red = vec4<f32>(1.0, 0.5, 0.5, 1.0);
    let yellow = vec4<f32>(1.0, 1.0, 0.5, 1.0);

    var heart: Surface;
    {
        let idx = repeat_idx(p2, 12.0) % 2.0;
        let w = pow(select(max(0.0, sin(uniforms.t * 4.0)), -min(0.0, sin(uniforms.t * 4.0)), idx == 0.0), 2.0);
        var sdg = smooth_gradient(heart_gradient(repeat_round(p2, 12.0) + vec2<f32>(0.0, -0.8), 0.125), 0.01*w);
        sdg = unfold_gradient(p2, sdg, 12.0);
        heart = Surface(sdg, red);
    }

    var star: Surface;
    {
        let a = uniforms.t * 0.2;
        let p2_rot = rotate(p2, a);
        let idx = repeat_idx(p2_rot, 16.0);
        let dir = select(1.0, -1.0, idx % 2.0 == 0.0);
        let a2 = t * 2.0 * dir;
        let p_repeat = repeat_round(p2_rot, 16.0) + vec2<f32>(0.0, -1.1);
        var sdg = smooth_gradient(star_gradient(rotate(p_repeat, a2), 0.125), 0.005);
        sdg = unfold_gradient(p2_rot, sdg, 16.0);
        sdg.gradient = rotate(sdg.gradient, a - a2);
        star = Surface(sdg, yellow);
    }

    var heart2: Surface;
    {
        let a = -uniforms.t * 0.1;
        let p2_rot = rotate(p2, a);
        let idx = repeat_idx(p2_rot, 20.0);
        let y_offset = sin(idx * 2.0 * PI / 4.0 + t * 2.0) * 0.05;
        let size = pow(sin(idx * 2.0 * PI / 6.0 + t * 2.0), 16.0) * 0.2 + 1.0;
        let p_repeat = (repeat_round(p2_rot, 20.0) + vec2<f32>(0.0, -1.3 + y_offset));
        var sdg = smooth_gradient(heart_gradient(p_repeat, 0.125*size), 0.01);
        sdg = unfold_gradient(p2_rot, sdg, 20.0);
        sdg.gradient = rotate(sdg.gradient, a);
        heart2 = Surface(sdg, red);
    }

    var star2: Surface;
    {
        let a = uniforms.t * 0.05;
        let p2_rot = rotate(p2, a);
        let idx = repeat_idx(p2_rot, 24.0);
        let p_repeat = repeat_round(p2_rot, 24.0) + vec2<f32>(0.0, -1.65);
        let a2 = smoothstep(0.0, 1.0, (t + idx / 8.0) % 3.0) * 2.0 * PI;
        let a3 = -uniforms.t * 0.15;
        var sdg = smooth_gradient(star_gradient(rotate(p_repeat, a2 + a3), 0.125), 0.005);
        sdg = unfold_gradient(p2_rot, sdg, 24.0);
        sdg.gradient = rotate(sdg.gradient, a - a2 - a3);
        star2 = Surface(sdg, yellow);
    }

    let k = 0.01;
    var surface = smin_surface(smin_surface(heart, star, k), smin_surface(heart2, star2, k), k);
    return surface;
}

fn circle(p: vec2<f32>, r: f32) -> SdfGradient {
    let d = length(p) - r;
    return SdfGradient(d, normalize(p));
}

fn rectangle(p: vec2<f32>, size: vec2<f32>) -> f32 {
    let d = abs(p)-size;
    return length(max(d,vec2<f32>(0.0,0.0))) + min(max(d.x,d.y),0.0);
}

fn rectangle_gradient(p: vec2<f32>, b: vec2<f32>) -> SdfGradient {
    let w = abs(p) - b;
    let s = vec2<f32>(select(1.0, -1.0, p.x < 0.0), select(1.0, -1.0, p.y < 0.0));
    let g = max(w.x, w.y);
    let q = max(w, vec2<f32>(0.0, 0.0));
    let l = length(q);
    let d = select(g, l, g > 0.0);
    let grad_dir = select(
        select(vec2<f32>(0.0, 1.0), vec2<f32>(1.0, 0.0), w.x > w.y),  // interior: dominant axis
        q / l,                                                         // exterior
        g > 0.0
    );
    let grad = s * grad_dir;
    return SdfGradient(d, grad);
}

fn rounded_rectangle_gradient(p: vec2<f32>, b: vec2<f32>, r: f32) -> SdfGradient {
    var sdg = rectangle_gradient(p, b - vec2<f32>(r));
    sdg.d -= r;
    return sdg;
}

fn oriented_rectangle(p: vec2<f32>, a: vec2<f32>, b: vec2<f32>, th: f32) -> f32 {
    let l = length(b - a);
    let d = (b - a) / l;
    var q = p - (a + b) * 0.5;
    q = mat2x2<f32>(d.x, -d.y, d.y, d.x) * q;
    q = abs(q) - vec2<f32>(l, th) * 0.5;
    return length(max(q, vec2<f32>(0.0, 0.0))) + min(max(q.x, q.y), 0.0);
}

fn heart(p_in: vec2<f32>, r: f32) -> f32 {
    var p = p_in;
    p.x = abs(p.x);
    p.y *= -1.0;
    p /= r;
    p.y += 0.5;

    if p.y+p.x>1.0 {
        return sqrt(dot2(p-vec2(0.25,0.75))) - sqrt(2.0)/4.0;
    }
    return sqrt(min(dot2(p-vec2(0.00,1.00)),
                    dot2(p-0.5*max(p.x+p.y,0.0)))) * sign(p.x-p.y);
}

fn heart_gradient(p_in: vec2<f32>, r_in: f32) -> SdfGradient {
    let sx = select(1.0, -1.0, p_in.x < 0.0);
    var p = p_in;
    p.x = abs(p.x);
    p /= r_in;

    if (p.y + p.x > 1.0) {
        let r = sqrt(2.0) / 4.0;
        let q0 = p - vec2<f32>(0.25, 0.75);
        let l = length(q0);
        var d = vec3<f32>(l - r, q0.x / l, q0.y / l);
        d.y *= sx;
        d.x *= r_in;
        return SdfGradient(d.x, vec2<f32>(d.y, d.z));
    } else {
        let q1 = p - vec2<f32>(0.0, 1.0);
        let q2 = p - 0.5 * max(p.x + p.y, 0.0);
        let d1 = vec3<f32>(dot(q1, q1), q1.x, q1.y);
        let d2 = vec3<f32>(dot(q2, q2), q2.x, q2.y);
        var d = select(d2, d1, d1.x < d2.x);
        d.x = sqrt(d.x);
        let inv = 1.0 / d.x;
        d.y *= inv;
        d.z *= inv;
        d *= select(-1.0, 1.0, p.x > p.y);
        d.y *= sx;
        d.x *= r_in;
        return SdfGradient(d.x, vec2<f32>(d.y, d.z));
    }
}

fn star(p_in: vec2<f32>, r: f32) -> f32 {
    let k1x = 0.809016994; // cos(π/5)
    let k2x = 0.309016994; // sin(π/10)
    let k1y = 0.587785252; // sin(π/5)
    let k2y = 0.951056516; // cos(π/10)
    let k1z = 0.726542528; // tan(π/5)
    let v1 = vec2<f32>(k1x, -k1y);
    let v2 = vec2<f32>(-k1x, -k1y);
    let v3 = vec2<f32>(k2x, -k2y);

    var p = p_in;
    p.x = abs(p.x);
    p -= 2.0 * max(dot(v1, p), 0.0) * v1;
    p -= 2.0 * max(dot(v2, p), 0.0) * v2;
    p.x = abs(p.x);
    p.y -= r;
    return length(p - v3 * clamp(dot(p, v3), 0.0, k1z * r))
           * sign(p.y * v3.x - p.x * v3.y);
}

fn star_gradient2(p_in: vec2<f32>, r: f32) -> SdfGradient {
    let h = 1e-3;
    let d = star(p_in, r);
    let dx = star(p_in + vec2<f32>(h, 0), r);
    let dy = star(p_in + vec2<f32>(0, h), r);
    let grad = vec2<f32>(dx - d, dy - d) / h;
    return SdfGradient(d, grad);
}

fn star_gradient(p_in: vec2<f32>, r: f32) -> SdfGradient {
    let k1x = 0.809016994;
    let k2x = 0.309016994;
    let k1y = 0.587785252;
    let k2y = 0.951056516;
    let k1z = 0.726542528;
    let v1 = vec2<f32>(k1x, -k1y);
    let v2 = vec2<f32>(-k1x, -k1y);
    let v3 = vec2<f32>(k2x, -k2y);

    var p = p_in;

    // fold 1: abs(x)  -> track sign
    let s0 = sign(p.x);          // +1 or -1 (treat 0 as +1 if you like)
    p.x = abs(p.x);

    // fold 2: reflect across v1 if active
    let a1 = dot(v1, p);
    let active1 = a1 > 0.0;
    if (active1) { p -= 2.0 * a1 * v1; }

    // fold 3: reflect across v2 if active
    let a2 = dot(v2, p);
    let active2 = a2 > 0.0;
    if (active2) { p -= 2.0 * a2 * v2; }

    // fold 4: abs(x) again
    let s1 = sign(p.x);
    p.x = abs(p.x);

    p.y -= r;

    // distance + raw gradient in the folded frame
    let w = p - v3 * clamp(dot(p, v3), 0.0, k1z * r);
    let sgn = sign(p.y * v3.x - p.x * v3.y);
    let dist = length(w) * sgn;

    var g = normalize(w) * sgn;   // gradient w.r.t. folded p

    // ---- chain-rule back through the folds, in reverse order ----

    // undo fold 4 (abs x): multiply x-component by s1
    g.x *= s1;

    // undo fold 3 (reflect across v2): apply R2 = I - 2 v2 v2^T  (symmetric)
    if (active2) { g -= 2.0 * dot(v2, g) * v2; }

    // undo fold 2 (reflect across v1)
    if (active1) { g -= 2.0 * dot(v1, g) * v1; }

    // undo fold 1 (abs x): multiply x-component by s0
    g.x *= s0;

    return SdfGradient(dist, g);
}

fn eqt_sdf(p: vec2<f32>) -> f32 {
    let e = letter_e(p + vec2<f32>(1.0, 0.0));
    let q = letter_q(p);
    let t = letter_t(p + vec2<f32>(-1.0, 0.0));
    let d = min(min(e, q), t);
    return d;
}

fn eqt_sdf_gradient(p: vec2<f32>) -> SdfGradient {
    let h = 1e-3;
    let d = eqt_sdf(p);
    let dx = eqt_sdf(p + vec2<f32>(h, 0));
    let dy = eqt_sdf(p + vec2<f32>(0, h));
    let grad = vec2<f32>(dx - d, dy - d) / h;
    return SdfGradient(d, grad);
}

fn eqt_logo_sdf(p_in: vec2<f32>) -> Surface {
    let p = p_in * 1.5;
    let p_e = p + vec2<f32>(1.3, 0.0);
    let p_q = p + vec2<f32>(0.0, 0.0);
    let p_t = p + vec2<f32>(-1.3, 0.0);
    let e = smin_surface(
        smin_surface(
            with_color(rectangle_gradient(p_e + vec2<f32>(0.55, 0.0), vec2<f32>(0.08, 0.5)), EQT_ORANGE),
            with_color(rectangle_gradient(p_e + vec2<f32>(0.0, 0.42), vec2<f32>(0.3, 0.08)), EQT_ORANGE),
            0.0,
        ),
        smin_surface(
            with_color(rectangle_gradient(p_e + vec2<f32>(0.0, 0.0), vec2<f32>(0.3, 0.08)), EQT_ORANGE),
            with_color(rectangle_gradient(p_e + vec2<f32>(0.0, -0.42), vec2<f32>(0.3, 0.08)), EQT_ORANGE),
            0.0,
        ),
        0.0,
    );
    let q = stylized_q_gradient(p_q);
    let t = smin_surface(
        with_color(rectangle_gradient(p_t + vec2<f32>(0.0, -0.2), vec2<f32>(0.08, 0.3)), EQT_ORANGE),
        with_color(rectangle_gradient(p_t + vec2<f32>(0.0, 0.42), vec2<f32>(0.5, 0.08)), EQT_ORANGE),
        0.0,
    );
    let q_surface = Surface(q, EQT_ORANGE);
    let s = smin_surface(smin_surface(e, q_surface, 0.0), t, 0.0);
    return s;
}

fn stylized_q(p: vec2<f32>) -> f32 {
    let a = 3.14159*0.75;
    let n = vec2<f32>(cos(a), sin(a));
    let a2 = 3.14159*0.75;
    return min(
        ring(p, n, 0.42, 0.16, a2),
        oriented_rectangle(p, vec2<f32>(0.05, 0.05), vec2<f32>(0.45, 0.45), 0.16),
    );
}

fn stylized_q_gradient(p: vec2<f32>) -> SdfGradient {
    let h = 1e-3;
    let d = stylized_q(p);
    let dx = stylized_q(p + vec2<f32>(h, 0));
    let dy = stylized_q(p + vec2<f32>(0, h));
    let grad = vec2<f32>(dx - d, dy - d) / h;
    return SdfGradient(d, grad);
}

fn letter_a(p: vec2<f32>) -> f32 {
    let left_base = parallelogram(p + vec2<f32>(-0.20, 0.0), 0.1, 0.5, 0.20);
    let right_base = parallelogram(p + vec2<f32>(0.20, 0.0), 0.1, 0.5, -0.20);
    let bar = trapezoid(p + vec2<f32>(0.0, -0.1), 0.2, 0.3, 0.1);
    let d = min(min(left_base, right_base), bar);
    return d;
}

fn letter_e(p: vec2<f32>) -> f32 {
    let left = rectangle(p + vec2<f32>(0.30, 0.0), vec2<f32>(0.1, 0.5));
    let top = rectangle(p + vec2<f32>(0.0, 0.4), vec2<f32>(0.4, 0.1));
    let middle = rectangle(p + vec2<f32>(0.1, 0.0), vec2<f32>(0.3, 0.1));
    let bottom = rectangle(p + vec2<f32>(0.0, -0.4), vec2<f32>(0.4, 0.1));
    let d = min(min(left, top), min(middle, bottom));
    return d;
}

fn letter_q(p: vec2<f32>) -> f32 {
    let circle = onion(circle(p, 0.4).d, 0.1);
    let rectangle = oriented_rectangle(p, vec2<f32>(0.15, 0.15), vec2<f32>(0.45, 0.45), 0.2);
    let d = min(circle, rectangle);
    return d;
}

fn letter_t(p: vec2<f32>) -> f32 {
    let stem = rectangle(p + vec2<f32>(0.0, 0.0), vec2<f32>(0.1, 0.5));
    let arm = rectangle(p + vec2<f32>(0.0, 0.4), vec2<f32>(0.4, 0.1));
    return min(stem, arm);
}

fn letter_v(p: vec2<f32>) -> f32 {
    let left_base = parallelogram(p + vec2<f32>(0.20, 0.0), 0.12, 0.5, 0.20);
    let right_base = parallelogram(p + vec2<f32>(-0.20, 0.0), 0.12, 0.5, -0.20);
    let d = min(left_base, right_base);
    return d;
}

fn ring(p_in: vec2<f32>, n: vec2<f32>, r: f32, th: f32, angle: f32) -> f32 {
    var p = p_in;
    let c = cos(angle);
    let s = sin(angle);
    p = mat2x2<f32>(c, -s, s, c) * p;
    p.x = abs(p.x);
    p = mat2x2<f32>(n.x, n.y, -n.y, n.x) * p;
    return max(abs(length(p) - r) - th * 0.5,
               length(vec2<f32>(p.x, max(0.0, abs(r - p.y) - th * 0.5))) * sign(p.x));
}

fn triangle_equilateral(p_in: vec2<f32>, r: f32) -> f32 {
    let k = sqrt(3.0);
    var p = p_in;
    p.x = abs(p.x) - r;
    p.y = p.y + r / k;
    if p.x + k * p.y > 0.0 {
        p = vec2<f32>(p.x - k * p.y, -k * p.x - p.y) / 2.0;
    }
    p.x -= clamp(p.x, -2.0 * r, 0.0);
    return -length(p) * sign(p.y);
}

fn triangle_isosceles(p_in: vec2<f32>, q: vec2<f32>) -> f32 {
    var p = p_in;
    p.x = abs(p.x);
    let a = p - q * clamp(dot(p, q) / dot(q, q), 0.0, 1.0);
    let b = p - q * vec2<f32>(clamp(p.x / q.x, 0.0, 1.0), 1.0);
    let s = -sign(q.y);
    let d = min(vec2<f32>(dot(a, a), s * (p.x * q.y - p.y * q.x)),
                vec2<f32>(dot(b, b), s * (p.y - q.y)));
    return -sqrt(d.x) * sign(d.y);
}

fn trapezoid(p_in: vec2<f32>, r1: f32, r2: f32, he: f32) -> f32 {
    let k1 = vec2<f32>(r2, he);
    let k2 = vec2<f32>(r2 - r1, 2.0 * he);
    var p = p_in;
    p.x = abs(p.x);
    let ca = vec2<f32>(p.x - min(p.x, select(r2, r1, p.y < 0.0)), abs(p.y) - he);
    let cb = p - k1 + k2 * clamp(dot(k1 - p, k2) / dot2(k2), 0.0, 1.0);
    let s = select(1.0, -1.0, cb.x < 0.0 && ca.y < 0.0);
    return s * sqrt(min(dot2(ca), dot2(cb)));
}

fn parallelogram(p_in: vec2<f32>, wi: f32, he: f32, sk: f32) -> f32 {
    let e = vec2<f32>(sk, he);
    var p = select(p_in, -p_in, p_in.y < 0.0);
    var w = p - e;
    w.x -= clamp(w.x, -wi, wi);
    var d = vec2<f32>(dot(w, w), -w.y);
    let s = p.x * e.y - p.y * e.x;
    p = select(p, -p, s < 0.0);
    var v = p - vec2<f32>(wi, 0.0);
    v -= e * clamp(dot(v, e) / dot(e, e), -1.0, 1.0);
    d = min(d, vec2<f32>(dot(v, v), wi * he - abs(s)));
    return sqrt(d.x) * sign(-d.y);
}

fn translate(p: vec2<f32>, offset: vec2<f32>) -> vec2<f32> {
    return p - offset;
}

fn dot2(p: vec2<f32>) -> f32 {
    return dot(p, p);
}

fn onion( d: f32, r: f32 ) -> f32 {
  return abs(d) - r;
}

fn cmul(a: vec2<f32>, b: vec2<f32>) -> vec2<f32> {
    return vec2<f32>(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x);
}

fn modulo_squared(z: vec2<f32>) -> f32 {
    return dot(z, z);
}

fn to_linear(color: vec3<f32>) -> vec3<f32> {
    return pow(color, vec3<f32>(2.2));
}

fn to_srgb(color: vec3<f32>) -> vec3<f32> {
    return pow(color, vec3<f32>(1.0 / 2.2));
}

fn to_linear4(color: vec4<f32>) -> vec4<f32> {
    return vec4<f32>(to_linear(color.rgb), color.a);
}

fn to_srgb4(color: vec4<f32>) -> vec4<f32> {
    return vec4<f32>(to_srgb(color.rgb), color.a);
}

fn mix_srgb(a: vec3<f32>, b: vec3<f32>, t: f32) -> vec3<f32> {
    return to_srgb(mix(to_linear(a), to_linear(b), t));
}

fn mix_srgb4(a: vec4<f32>, b: vec4<f32>, t: f32) -> vec4<f32> {
    return vec4<f32>(mix_srgb(a.rgb, b.rgb, t), mix(a.a, b.a, t));
}