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

void ShadeLight(Light light, float3 viewDirectionWS, float3 normalWS, half roughness, half NoV, half3 f0, half3 energyCompensation, inout half3 color, inout half3 specular)
{
    float3 lightDirection = light.direction;
    float3 lightHalfVector = normalize(lightDirection + viewDirectionWS);
    half lightNoL = saturate(dot(normalWS, lightDirection));
    half lightLoH = saturate(dot(lightDirection, lightHalfVector));
    half lightNoH = saturate(dot(normalWS, lightHalfVector));

    half3 lightColor = light.attenuation * light.color;
    half3 lightFinalColor = lightNoL * lightColor;

#ifdef UNITY_PASS_FORWARDBASE
    #if !defined(QUALITY_LOW) && !defined(LIGHTMAP_ON)
        lightFinalColor *= Filament::Fd_Burley(roughness, NoV, lightNoL, lightLoH);
    #endif
#endif

    color += lightFinalColor;

    #ifndef _SPECULARHIGHLIGHTS_OFF

        half clampedRoughness = max(roughness * roughness, 0.002);

        #ifdef _ANISOTROPY
            // half at = max(clampedRoughness * (1.0 + surfaceDescription.Anisotropy), 0.001);
            // half ab = max(clampedRoughness * (1.0 - surfaceDescription.Anisotropy), 0.001);

            // float3 l = light.direction;
            // float3 t = sd.tangentWS;
            // float3 b = sd.bitangentWS;
            // float3 v = viewDirectionWS;

            // half ToV = dot(t, v);
            // half BoV = dot(b, v);
            // half ToL = dot(t, l);
            // half BoL = dot(b, l);
            // half ToH = dot(t, lightHalfVector);
            // half BoH = dot(b, lightHalfVector);

            // half3 F = Filament::F_Schlick(lightLoH, sd.f0) * energyCompensation;
            // half D = Filament::D_GGX_Anisotropic(lightNoH, lightHalfVector, t, b, at, ab);
            // half V = Filament::V_SmithGGXCorrelated_Anisotropic(at, ab, ToV, BoV, ToL, BoL, NoV, lightNoL);
        #else
            half3 F = Filament::F_Schlick(lightLoH, f0) * energyCompensation;
            half D = Filament::D_GGX(lightNoH, clampedRoughness);
            half V = Filament::V_SmithGGXCorrelated(NoV, lightNoL, clampedRoughness);
        #endif

        specular += max(0.0, (D * V) * F) * lightFinalColor;
    #endif
}