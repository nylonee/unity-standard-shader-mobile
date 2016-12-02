using System;
using UnityEngine;

namespace UnityStandardAssets.ImageEffects
{
  [RequireComponent(typeof(Camera))]
  [AddComponentMenu("Image Effects/Custom/Mobile Bloom and Tonemapping")]
  public class MobileBloomAndTonemapping : PostEffectsBase
  {

    [Range(0.0f, 1.5f)]
    public float bloomThreshold = 0.25f;
    [Range(0.0f, 2.5f)]
    public float bloomIntensity = 0.75f;

    [Range(0.25f, 5.5f)]
    public float bloomBlurSize = 1.0f;

    // CURVE parameters
    public AnimationCurve remapCurve;
    private Texture2D curveTex = null;

    // usual stuff
    public Shader bloomAndTonemapShader = null;
    private Material bloomAndTonemapMaterial = null;

    public override bool CheckResources()
    {
      CheckSupport(false, true); // Need depth, and need hdr

      bloomAndTonemapMaterial = CheckShaderAndCreateMaterial(bloomAndTonemapShader, bloomAndTonemapMaterial);
      if(!curveTex)
      {
        curveTex = new Texture2D(256, 1, TextureFormat.ARGB32, false, true);
        curveTex.filterMode = FilterMode.Bilinear;
        curveTex.wrapMode = TextureWrapMode.Clamp;
        curveTex.hideFlags = HideFlags.DontSave;
      }

      if(!isSupported)
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
        if(remapCurve.length > 0)
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
      if (bloomAndTonemapMaterial)
      {
        DestroyImmediate(bloomAndTonemapMaterial);
        bloomAndTonemapMaterial = null;
      }
      if (curveTex)
      {
        DestroyImmediate(curveTex);
        curveTex = null;
      }
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

      float rangeScale = UpdateCurve(); // Gets mapped into a half in shader

      bloomAndTonemapMaterial.SetVector("_Parameter", new Vector4(bloomBlurSize * 0.5f, 0.0f, bloomThreshold, bloomIntensity));
      bloomAndTonemapMaterial.SetFloat("_RangeScale", rangeScale);
      bloomAndTonemapMaterial.SetTexture("_Curve", curveTex);
      source.filterMode = FilterMode.Bilinear;

      var rtW = source.width / 4;
      var rtH = source.height / 4;

      // downsample
      RenderTexture rtBloom = RenderTexture.GetTemporary(rtW, rtH, 0, source.format);
      rtBloom.filterMode = FilterMode.Bilinear;
      Graphics.Blit(source, rtBloom, bloomAndTonemapMaterial, 1);

      bloomAndTonemapMaterial.SetVector("_Parameter", new Vector4(bloomBlurSize * 0.5f + 1.0f, 0.0f, bloomThreshold, bloomIntensity));

      // vertical blur
      RenderTexture rt2 = RenderTexture.GetTemporary(rtW, rtH, 0, source.format);
      rt2.filterMode = FilterMode.Bilinear;
      Graphics.Blit(rtBloom, rt2, bloomAndTonemapMaterial, 2);
      RenderTexture.ReleaseTemporary(rtBloom);
      rtBloom = rt2;

      // horizontal blur
      rt2 = RenderTexture.GetTemporary(rtW, rtH, 0, source.format);
      rt2.filterMode = FilterMode.Bilinear;
      Graphics.Blit(rtBloom, rt2, bloomAndTonemapMaterial, 3);
      RenderTexture.ReleaseTemporary(rtBloom);
      rtBloom = rt2;

      bloomAndTonemapMaterial.SetTexture("_Bloom", rtBloom);

      Graphics.Blit(source, destination, bloomAndTonemapMaterial, 0);

      RenderTexture.ReleaseTemporary(rtBloom);

    }

  }
}
