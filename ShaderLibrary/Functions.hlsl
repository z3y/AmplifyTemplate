float3 Orthonormalize(float3 tangent, float3 normal)
{
    return normalize(tangent - dot(tangent, normal) * normal);
}