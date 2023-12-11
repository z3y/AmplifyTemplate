Texture2D<float4> _DFG;
SamplerState custom_bilinear_clamp_sampler;

// #ifdef UNITY_SAMPLE_FULL_SH_PER_PIXEL
//     #undef UNITY_SAMPLE_FULL_SH_PER_PIXEL
// #endif
// #define UNITY_SAMPLE_FULL_SH_PER_PIXEL 1

#include "Filament.hlsl"

float3 Orthonormalize(float3 tangent, float3 normal)
{
    return normalize(tangent - dot(tangent, normal) * normal);
}

#ifdef UNITY_PBS_USE_BRDF2
    #define QUALITY_LOW
#endif

struct Light
{
    float3 direction;
    half3 color;
    half attenuation;

    static Light Initialize(Varyings varyings)
    {
        Light light = (Light)0;

        #if !defined(USING_LIGHT_MULTI_COMPILE)
            return light;
        #endif

        light.direction = Unity_SafeNormalize(UnityWorldSpaceLightDir(varyings.positionWS));
        light.color = _LightColor0.rgb;

        UNITY_LIGHT_ATTENUATION(attenuation, varyings, varyings.positionWS.xyz);

        #if defined(HANDLE_SHADOWS_BLENDING_IN_GI) && defined(SHADOWS_SCREEN) && defined(LIGHTMAP_ON)
            half bakedAtten = UnitySampleBakedOcclusion(varyings.lightmapUV, varyings.positionWS);
            float zDist = dot(_WorldSpaceCameraPos -  varyings.positionWS, UNITY_MATRIX_V[2].xyz);
            float fadeDist = UnityComputeShadowFadeDistance(varyings.positionWS, zDist);
            attenuation = UnityMixRealtimeAndBakedShadows(attenuation, bakedAtten, UnityComputeShadowFade(fadeDist));
        #endif

        #if defined(UNITY_PASS_FORWARDBASE) && !defined(SHADOWS_SCREEN) && !defined(SHADOWS_SHADOWMASK)
            attenuation = 1.0;
        #endif

        light.attenuation = attenuation;

        #if defined(LIGHTMAP_SHADOW_MIXING) && defined(LIGHTMAP_ON)
            light.color *= UnityComputeForwardShadows(varyings.lightmapUV.xy, varyings.positionWS, varyings._shadowCoord);
        #endif

        return light;
    }
};
