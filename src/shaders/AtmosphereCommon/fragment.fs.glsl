precision highp float;
uniform float planetRadius;
uniform float realPlanetRadius;
uniform float atmoRadiusSquared;

#ifdef VOLUMETRIC_CLOUDS
const float windSpeedRatio = 0.0002;
uniform float cloudCover;
uniform float cloudBase;
uniform float cloudTop;
uniform vec3 windVector;
uniform float cloudThickness;
uniform float layerPosition;
uniform float baseThickness;
uniform float layer;
uniform float cloudBaseRadius;
uniform float cloudTopRadius;
#endif

/*
float cloudThickness = cloudTop - cloudBase;
float layerPosition = 0.1; // set the layer base to 10% of the cloud height
float baseThickness = cloudThickness * layerPosition;
float layer = cloudBase + baseThickness;
float cloudBase_radius = realPlanetRadius + cloudBase;
float cloudTop_radius = cloudBase_radius + cloudThickness;
*/

const float PI = 3.14159265359;
const float TWO_PI = 6.28318530718;
const float FOUR_PI = 12.5663706144;

#ifdef QUALITY_7
  #define PRIMARY_STEPS 16
  #define LIGHT_STEPS 4
  #define CLOUDS_MAX_LOD 1
  #define CLOUDS_MARCH_STEP 500.0
  #define CLOUDS_DENS_MARCH_STEP 100.0
  #define MAXIMUM_CLOUDS_STEPS 300
  #define DISTANCE_QUALITY_RATIO 0.00003
  #define CLOUD_SHADOWS
#elif defined QUALITY_6
  #define PRIMARY_STEPS 12
  #define LIGHT_STEPS 4
  #define CLOUDS_MAX_LOD 1
  #define CLOUDS_MARCH_STEP 500.0
  #define CLOUDS_DENS_MARCH_STEP 100.0
  #define MAXIMUM_CLOUDS_STEPS 200
  #define DISTANCE_QUALITY_RATIO 0.00004
  #define CLOUD_SHADOWS
#elif defined QUALITY_5
  #define PRIMARY_STEPS 9
  #define LIGHT_STEPS 3
  #define CLOUDS_MAX_LOD 1
  #define CLOUDS_MARCH_STEP 750.0
  #define CLOUDS_DENS_MARCH_STEP 150.0
  #define MAXIMUM_CLOUDS_STEPS 150
  #define DISTANCE_QUALITY_RATIO 0.00005
  #define CLOUD_SHADOWS
#elif defined QUALITY_4
  #define PRIMARY_STEPS 9
  #define LIGHT_STEPS 3
  #define CLOUDS_MAX_LOD 1
  #define CLOUDS_MARCH_STEP 750.0
  #define CLOUDS_DENS_MARCH_STEP 150.0
  #define MAXIMUM_CLOUDS_STEPS 100
  #define DISTANCE_QUALITY_RATIO 0.00007
  #define CLOUD_SHADOWS
#elif defined QUALITY_3
  #define PRIMARY_STEPS 6
  #define LIGHT_STEPS 2
  #define CLOUDS_MAX_LOD 0
  #define CLOUDS_MARCH_STEP 750.0
  #define CLOUDS_DENS_MARCH_STEP 150.0
  #define MAXIMUM_CLOUDS_STEPS 75
  #define DISTANCE_QUALITY_RATIO 0.0001
  #define CLOUD_SHADOWS
#elif defined QUALITY_2
  #define PRIMARY_STEPS 6
  #define LIGHT_STEPS 1
  #define CLOUDS_MAX_LOD 0
  #define CLOUDS_MARCH_STEP 1000.0
  #define CLOUDS_DENS_MARCH_STEP 200.0
  #define MAXIMUM_CLOUDS_STEPS 50
  #define DISTANCE_QUALITY_RATIO 0.0002
  #define CLOUD_SHADOWS
#elif defined QUALITY_1
  #define PRIMARY_STEPS 3
  #define LIGHT_STEPS 1
  #define CLOUDS_MAX_LOD 0
  #define CLOUDS_MARCH_STEP 1000.0
  #define CLOUDS_DENS_MARCH_STEP 200.0
  #define MAXIMUM_CLOUDS_STEPS 20
  #define DISTANCE_QUALITY_RATIO 0.0004
#elif defined QUALITY_0
  #define PRIMARY_STEPS 3
  #define LIGHT_STEPS 1
  #define CLOUDS_MAX_LOD 0
  #define CLOUDS_MARCH_STEP 1000.0
  #define CLOUDS_DENS_MARCH_STEP 200.0
  #define MAXIMUM_CLOUDS_STEPS 10
  #define DISTANCE_QUALITY_RATIO 0.0004
#else //DEFAULT
  #define PRIMARY_STEPS 9
  #define LIGHT_STEPS 2
  #define CLOUDS_MAX_LOD 1
  #define CLOUDS_MARCH_STEP 750.0
  #define CLOUDS_DENS_MARCH_STEP 150.0
  #define MAXIMUM_CLOUDS_STEPS 40
  #define DISTANCE_QUALITY_RATIO 0.0002
  #define CLOUD_SHADOWS
#endif

#define CLOUDS_MAX_VIEWING_DISTANCE 250000.0

vec2 raySphereIntersect(vec3 r0, vec3 rd, float sr) {
  float a = dot(rd, rd);
  float b = 2.0 * dot(rd, r0);
  float c = dot(r0, r0) - (sr * sr);
  float d = (b * b) - 4.0 * a * c;

  if(d < 0.0)
    return vec2(-1.0, -1.0);
  float squaredD = sqrt(d);

  return vec2((-b - squaredD) / (2.0 * a), (-b + squaredD) / (2.0 * a));
}

float reMap(float value, float old_low, float old_high, float new_low, float new_high) {
  return new_low + (value - old_low) * (new_high - new_low) / (old_high - old_low);
}

float saturate(float value) {
  return clamp(value, 0.0, 1.0);
}

float isotropic() {
  return 0.07957747154594767; //1.0 / (4.0 * PI);
}

float rayleigh(float costh) {
  return (3.0 / (16.0 * PI)) * (1.0 + pow(costh, 2.0));
}

float HenyeyGreenstein(float g, float costh) {
  return (1.0 - g * g) / (FOUR_PI * pow(1.0 + g * g - 2.0 * g * costh, 3.0 / 2.0));
}

float Schlick(float k, float costh) {
  return (1.0 - k * k) / (FOUR_PI * pow(1.0 - k * costh, 2.0));
}

// how bright the light is, affects the brightness of the atmosphere
vec3 light_intensity = vec3(100.0);//vec3(100.0);

// the amount rayleigh scattering scatters the colors (for earth: causes the blue atmosphere)
vec3 beta_ray = vec3(5.5e-6, 13.0e-6, 22.4e-6);//vec3(5.5e-6, 13.0e-6, 22.4e-6);

// the amount mie scattering scatters colors
vec3 beta_mie = vec3(21e-6); // vec3(21e-6);

// the amount of scattering that always occurs, can help make the back side of the atmosphere a bit brighter
vec3 beta_ambient = vec3(0.0);

// the direction mie scatters the light in (like a cone). closer to -1 means more towards a single direction
float g = 0.9;

// how high do you have to go before there is no rayleigh scattering?
float height_ray = 10e3;

// the same, but for mie
float height_mie = 3.2e3;

// 1.0 - how much extra the atmosphere blocks light
float density_multiplier = 4.0;

#ifdef ADVANCED_ATMOSPHERE
vec4 calculate_scattering(
  vec3 start, // the start of the ray (the camera position)
  vec3 dir, // the direction of the ray (the camera vector)
  float maxDistance, // the maximum distance the ray can travel (because something is in the way, like an object)
  vec3 light_dir
) {
  float a = dot(dir, dir);
  float b = 2.0 * dot(dir, start);
  float c = dot(start, start) - atmoRadiusSquared;
  float d = (b * b) - 4.0 * a * c;
  if(d < 0.0)
    return vec4(0.0);

  float squaredD = sqrt(d);
    // 射线的起点和终点
  vec2 ray_length = vec2(max((-b - squaredD) / (2.0 * a), 0.0), min((-b + squaredD) / (2.0 * a), maxDistance));

  if(ray_length.x > ray_length.y)
    return vec4(0.0);

  bool allow_mie = maxDistance > ray_length.y;
  float step_size_i = (ray_length.y - ray_length.x) / float(PRIMARY_STEPS);
  float ray_pos_i = ray_length.x;
  vec3 total_ray = vec3(0.0); // for rayleigh
  vec3 total_mie = vec3(0.0); // for mie
  vec2 opt_i = vec2(0.0);
  vec2 scale_height = vec2(height_ray, height_mie);
  float mu = dot(dir, light_dir);
  float mumu = mu * mu;
  float gg = g * g;
  float phase_ray = 3.0 / (50.2654824574) * (1.0 + mumu);
  float phase_mie = (allow_mie ? 3.0 : 0.5) / (25.1327412287) * ((1.0 - gg) * (mumu + 1.0)) / (pow(1.0 + gg - 2.0 * mu * g, 1.5) * (2.0 + gg));

  for(int i = 0; i < PRIMARY_STEPS; ++i) {
    vec3 pos_i = start + dir * (ray_pos_i + step_size_i);
    float height_i = length(pos_i) - planetRadius;
    vec2 density = exp(-height_i / scale_height) * step_size_i;

    opt_i += density;
    a = dot(light_dir, light_dir);
    b = 2.0 * dot(light_dir, pos_i);
    c = dot(pos_i, pos_i) - atmoRadiusSquared;
    d = (b * b) - 4.0 * a * c;

    if(d <= 0.0)
      d = 1.0; // not supposed to be required but this avoids the black singularity line at dusk and dawn
    float step_size_l = (-b + sqrt(d)) / (2.0 * a * float(LIGHT_STEPS));
    float ray_pos_l = 0.0;
    vec2 opt_l = vec2(0.0);

    for(int l = 0; l < LIGHT_STEPS; ++l) {
      vec3 pos_l = pos_i + light_dir * (ray_pos_l + step_size_l * 0.5);
      float height_l = length(pos_l) - planetRadius;
      opt_l += exp(-height_l / scale_height) * step_size_l;
      ray_pos_l += step_size_l;
    }

    vec3 attn = exp(-((beta_mie * (opt_i.y + opt_l.y)) + (beta_ray * (opt_i.x + opt_l.x))));
    total_ray += density.x * attn;
    total_mie += density.y * attn;
    ray_pos_i += step_size_i;
  }

  float opacity = length(exp(-((beta_mie * opt_i.y) + (beta_ray * opt_i.x)) * density_multiplier));
  return vec4((phase_ray * beta_ray * total_ray // rayleigh color
  + phase_mie * beta_mie * total_mie // mie
  + opt_i.x * beta_ambient // and ambient
  ) * light_intensity, 1.0 - opacity);
}
#endif

#ifdef VOLUMETRIC_CLOUDS
float hash(float p) {
  p = fract(p * .1031);
  p *= p + 33.33;
  p *= p + p;
  return fract(p);
}

float noise(in vec3 x) {
  vec3 p = floor(x);
  vec3 f = fract(x);
  f = f * f * (3.0 - 2.0 * f);
  float n = p.x + p.y * 157.0 + 113.0 * p.z;
  return mix(mix(mix(hash(n + 0.0), hash(n + 1.0), f.x), mix(hash(n + 157.0), hash(n + 158.0), f.x), f.y), mix(mix(hash(n + 113.0), hash(n + 114.0), f.x), mix(hash(n + 270.0), hash(n + 271.0), f.x), f.y), f.z);
}

int lastFlooredPosition;
float lastLiveCoverageValue = 0.0;

float cloudDensity(vec3 p, vec3 wind, int lod, inout float heightRatio) {
  float finalCoverage = cloudCover;

  if(finalCoverage <= 0.1) {
    return 0.0;
  }

  float height = length(p) - realPlanetRadius;
  heightRatio = (height - cloudBase) / cloudThickness;

  float positionResolution = 0.002;
  p = p * positionResolution + wind;

  float shape = noise(p * 0.3);
  float shapeHeight = noise(p * 0.05);
  float bn = 0.50000 * noise(p);
  p = p * 2.0;

  if(lod >= 1) {
    bn += 0.20000 * noise(p);
    p = p * 2.11;
  }

  float cumuloNimbus = saturate((shapeHeight - 0.5) * 2.0);
  cumuloNimbus *= saturate(1.0 - pow(heightRatio - 0.5, 2.0) * 4.0);
  float cumulus = saturate(1.0 - pow(heightRatio - 0.25, 2.0) * 25.0) * shapeHeight;
  float stratoCumulus = saturate(1.0 - pow(heightRatio - 0.12, 2.0) * 60.0) * (1.0 - shapeHeight);
  float dens = saturate(stratoCumulus + cumulus + cumuloNimbus) * 2.0 * finalCoverage;
  dens -= 1.0 - shape;
  dens -= bn;
  return clamp(dens, 0.0, 1.0);
}
#endif