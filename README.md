# Standard Shader (Mobile)
A shader written in Unity's ShaderLab and CG, designed for mobile devices. See [usage](USAGE.md)

![Example lighting](http://i.imgur.com/b1vUppR.png "Example lighting")  

*No external lighting has been passed in to create the lighting effect on this block*

This shader is kept fast by disabling shader features that are not being used during compilation
## Features
 * Supports lightmaps and exponential2 fog
 * Can adjust color tint, brightness and contrast
 * Specify a single point light for diffuse, specular and normal mapping effects
 * Can modify the location of the point light via script (eg. a sun moving across the sky)
 * Adjust point light's Blinn-Phong intensity (ambience, specular and diffuse)
 * Add a detail map, adjust strength and add a detail mask
 * Add an emission map, adjust strength
 * Add a normal map  

 ![Shader options](http://i.imgur.com/khtlPSX.png "Shader options")  

## Important Notes
 * Tested on Unity 5.4.0f3
 * Doesn't support shadow casting
 * No other lighting (except lightmaps) are passed in. If you need more lighting options, consider using a different shader.
