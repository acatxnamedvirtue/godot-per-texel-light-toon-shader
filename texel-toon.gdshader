shader_type spatial;                                                                                                            
render_mode depth_prepass_alphaw;                               

uniform sampler2D atlas : filter_nearest, repeat_disable;
uniform vec2 atlas_tiles = vec2(32.0, 32.0);

uniform bool clamp_diffuse_to_max = false;
uniform int cuts : hint_range(1, 8) = 3;
uniform float wrap : hint_range(-2.0, 2.0) = 0.0;
uniform float steepness : hint_range(1.0, 8.0) = 1.0;
uniform bool use_attenuation = true;

uniform bool use_specular = false;
uniform float specular_strength : hint_range(0.0, 1.0) = 0.5;
uniform float specular_shininess : hint_range(0.0, 32.0) = 16.0;

uniform bool use_rim = false;
uniform float rim_width : hint_range(0.0, 16.0) = 4.0;
uniform vec4 rim_color : source_color = vec4(1.0);

uniform bool use_ramp = false;
uniform sampler2D ramp : source_color;

uniform bool use_borders = false;
uniform float border_width = 0.01;

varying float tile_pixel_size;

float split_specular(float specular) {
    return step(0.5, specular);
}

void vertex() {
    ivec2 atlas_size = textureSize(atlas, 0);
    tile_pixel_size = float(atlas_size.x) / atlas_tiles.x;
}

void fragment() {
    vec2 tile_size_uv = 1.0 / atlas_tiles;
    vec2 final_uv = UV2 * tile_size_uv + UV * tile_size_uv;

    vec4 tex = texture(atlas, final_uv);
    if (tex.a < 0.1) discard;
    ALBEDO = tex.rgb;

    vec2 texel_size = vec2(1.0 / tile_pixel_size);
    vec2 center_uv = (floor(UV / texel_size) * texel_size) + texel_size * 0.5;
    vec2 d_uv = center_uv - UV;

    vec2 d_uvd_s = dFdx(UV);
    vec2 d_uvd_t = dFdy(UV);
    float det = d_uvd_s[0] * d_uvd_t[1] - d_uvd_t[0] * d_uvd_s[1];
    mat2 d_std_uv = mat2(
        vec2( d_uvd_t[1], -d_uvd_t[0]),
        vec2(-d_uvd_s[1],  d_uvd_s[0])
    ) * (1.0 / det);
    vec2 d_st = d_uv * d_std_uv;

    vec3 d_xyz = dFdx(VERTEX) * d_st[0] + dFdy(VERTEX) * d_st[1];
    LIGHT_VERTEX += d_xyz;
}

void light() {
    float attenuation = use_attenuation ? ATTENUATION : 1.0;

    float NdotL = dot(NORMAL, LIGHT);
    float diffuse_amount = NdotL + (attenuation - 1.0) + wrap;
    diffuse_amount *= steepness;
    float cuts_inv = 1.0 / float(cuts);
    float diffuse_stepped = clamp(
        diffuse_amount + mod(1.0 - diffuse_amount, cuts_inv),
        0.0, 1.0
    );

    float border = 0.0;
    if (use_borders) {
        float corr_border_width = length(cross(NORMAL, LIGHT)) * border_width * steepness;
        border = step(diffuse_stepped - corr_border_width, diffuse_amount)
                - step(1.0 - corr_border_width, diffuse_amount);
    }

    vec3 diffuse = ALBEDO.rgb * LIGHT_COLOR / PI;
    if (use_ramp) {
        diffuse *= texture(ramp, vec2(diffuse_stepped * (1.0 - border), 0.0)).rgb;
    } else {
        diffuse *= diffuse_stepped * (1.0 - border);
    }

    if (clamp_diffuse_to_max) {
        DIFFUSE_LIGHT = max(DIFFUSE_LIGHT, diffuse);
    } else {
        DIFFUSE_LIGHT += diffuse;
    }

    if (use_specular) {
        vec3 H = normalize(LIGHT + VIEW);
        float NdotH = dot(NORMAL, H);
        float spec = max(pow(NdotH, specular_shininess * specular_shininess), 0.0) * attenuation;
        SPECULAR_LIGHT += specular_strength * split_specular(spec) * LIGHT_COLOR;
    }

    if (use_rim) {
        float rim_light = pow(1.0 - dot(NORMAL, VIEW), rim_width);
        SPECULAR_LIGHT += rim_light * rim_color.rgb * rim_color.a * LIGHT_COLOR / PI;
    }
}
