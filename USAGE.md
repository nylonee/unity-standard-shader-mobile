# Quick guide
To use this shader on a material, copy the StandardMobile.shader and StandardMobile.cginc files to your Asset folder, then select `Mobile/Standard` as your shader in the material properties.

## Feature toggles
You can choose which features you want compiled into the final code using the shader properties. The toggles available are:
 * Color, Brightness, Contrast toggle
 * Point Light Toggle
 * Detail Map Toggle
 * Detail Mask Toggle
 * Emission Map Toggle
 * Normal Map Toggle

*Note: Some features rely on others in order to function properly. For example, you can't use a detail mask without having a detail map, and normal mapping is ineffective without a point light.*

### Color, Brightness and Contrast
 A color tint can be applied to the final texture by defining color (alpha isn't used currently, if you want a more transparent tint, choose a whiter tone).  
 Brightness and contrast can also be toggled, default is Brightness 0, Contrast 1.

 *Note: Color tint, brightness and contrast is applied at the very end of the fragment shader, meaning that the final image will be affected, regardless of what other features are on*

### Point Light
 A single point light can be defined, including color and position. The point light's relative intensity can then be adjusted (ambience, specular and diffuse intensity can be tweaked to give the desired effect). The light is calculated using [Blinn-Phong's](https://en.wikipedia.org/wiki/Blinn%E2%80%93Phong_shading_model) model.  

 This will only affect the material the shader is attached to. If it feels awkward having a point light with no emitting object, create a GameObject (eg. a yellow sphere) and have a script update the light position in the shader. This will also give you flexibility to manipulate the light source.  

 Example code that finds all materials with the `Mobile/Standard` shader, and updates the point light position based on the GameObject's position that the script is attached to.

```
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class PointLight : MonoBehaviour {

  List<Material> mats;

  // Use this for initialization
  void Start () {
    // Find all materials that contain the mobile shader
    mats = FindShaders("Mobile/Standard");
    transform.hasChanged = false;
  }

  // Update is called once per frame
  void Update()
  {
    if (transform.hasChanged)
    {
      foreach (Material mat in mats)
      {
        // Update the point lights in each material that contains the shader
        mat.SetVector("_PointLightPosition", transform.position);
      }
      transform.hasChanged = false;
    }
  }

  private List<Material> FindShaders(string shaderName)
  {
    List<Material> armat = new List<Material>();

    Renderer[] arrend = (Renderer[])Resources.FindObjectsOfTypeAll(typeof(Renderer));
    foreach (Renderer rend in arrend)
      foreach (Material mat in rend.sharedMaterials)
        if (!armat.Contains(mat) && mat != null && mat.shader != null && mat.shader.name != null && mat.shader.name == shaderName)
          armat.Add(mat);

    return armat;
  }
}

```

### Detail Map and Detail Mask
Add a detail map, choose the strength of the map, and add a detail mask to hide parts of the main texture you don't want detail mapped. See Unity's [Secondary Maps](https://docs.unity3d.com/Manual/StandardShaderMaterialParameterDetail.html) for more examples of how to use Detail Maps and Detail Masks

### Emission Map Toggle
Add an emission map (see Unity's [Emission](https://docs.unity3d.com/Manual/StandardShaderMaterialParameterEmission.html) parameter)

### Normal Map Toggle
Add a normal map, to give better detail. Because normal maps require a lighting model, the Point Light must be toggled in order to see the normal mapping effect, since this is the only 'dynamic' light source that's accepted into the shader. See Unity's [Normal](https://docs.unity3d.com/Manual/StandardShaderMaterialParameterNormalMap.html) parameter for more details on normal maps.  
A feature of this normal map which you don't usually see in other shaders, is the ability to tweak how affected the material is, using the strength slider.
