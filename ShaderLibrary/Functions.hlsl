#include "Filament.hlsl"

float3 Orthonormalize(float3 tangent, float3 normal)
{
    return normalize(tangent - dot(tangent, normal) * normal);
}

#ifdef UNITY_PBS_USE_BRDF2
    #define QUALITY_LOW
#endif