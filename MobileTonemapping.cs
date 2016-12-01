// Adapted from ImageEffects/Tonemapping, simplified to only User Curve for mobile
using System;
using UnityEngine;

namespace UnityStandardAssets.ImageEffects
{
    [ExecuteInEditMode]
    [RequireComponent(typeof(Camera))]
    [AddComponentMenu("Image Effects/Custom/MobileTonemapping")]
    public class MobileTonemapping : PostEffectsBase
    {

        // CURVE parameter
        public AnimationCurve remapCurve;
        private Texture2D curveTex = null;

        // usual & internal stuff
        public Shader tonemapper = null;
        private Material tonemapMaterial = null;
        private RenderTexture rt = null;
        private RenderTextureFormat rtFormat = RenderTextureFormat.ARGBHalf;


        public override bool CheckResources()
        {
            CheckSupport(false, true);

            tonemapMaterial = CheckShaderAndCreateMaterial(tonemapper, tonemapMaterial);
            if (!curveTex)
            {
                curveTex = new Texture2D(256, 1, TextureFormat.ARGB32, false, true);
                curveTex.filterMode = FilterMode.Bilinear;
                curveTex.wrapMode = TextureWrapMode.Clamp;
                curveTex.hideFlags = HideFlags.DontSave;
            }

            if (!isSupported)
                ReportAutoDisable();
            return isSupported;
        }


        public float UpdateCurve()
        {
            float range = 1.0f;
            if (remapCurve.keys.Length < 1)
                remapCurve = new AnimationCurve(new Keyframe(0, 0), new Keyframe(2, 1));
            if (remapCurve != null)
            {
                if (remapCurve.length > 0)
                    range = remapCurve[remapCurve.length - 1].time;
                for (float i = 0.0f; i <= 1.0f; i += 1.0f / 255.0f)
                {
                    float c = remapCurve.Evaluate(i * 1.0f * range);
                    curveTex.SetPixel((int)Mathf.Floor(i * 255.0f), 0, new Color(c, c, c));
                }
                curveTex.Apply();
            }
            return 1.0f / range;
        }


        private void OnDisable()
        {
            if (rt)
            {
                DestroyImmediate(rt);
                rt = null;
            }
            if (tonemapMaterial)
            {
                DestroyImmediate(tonemapMaterial);
                tonemapMaterial = null;
            }
            if (curveTex)
            {
                DestroyImmediate(curveTex);
                curveTex = null;
            }
        }


        private bool CreateInternalRenderTexture()
        {
            if (rt)
            {
                return false;
            }
            rtFormat = SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.RGHalf) ? RenderTextureFormat.RGHalf : RenderTextureFormat.ARGBHalf;
            rt = new RenderTexture(1, 1, 0, rtFormat);
            rt.hideFlags = HideFlags.DontSave;
            return true;
        }


        // attribute indicates that the image filter chain will continue in LDR
        [ImageEffectTransformsToLDR]
        private void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            if (CheckResources() == false)
            {
                Graphics.Blit(source, destination);
                return;
            }

            // clamp some values to not go out of a valid range
            
            float rangeScale = UpdateCurve(); // Gets mapped into a half in shader
            tonemapMaterial.SetFloat("_RangeScale", rangeScale);
            tonemapMaterial.SetTexture("_Curve", curveTex);
            Graphics.Blit(source, destination, tonemapMaterial);
            return;
        }
    }
}
