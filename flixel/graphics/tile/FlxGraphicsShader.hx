package flixel.graphics.tile;

import openfl.display.GraphicsShader;

class FlxGraphicsShader extends GraphicsShader
{
	@:glVertexHeader("
		attribute vec4 colorMultiplier;
		attribute vec4 colorOffset;
		uniform bool hasColorTransform;
	", true)
	@:glVertexBody("
		openfl_ColorOffsetv = colorOffset;
		openfl_ColorMultiplierv = colorMultiplier;
	", true)
	@:glFragmentHeader("
		uniform bool hasTransform;  // TODO: Is this still needed? Apparently, yes!
		uniform bool hasColorTransform;
		uniform bool premultiplyAlpha;

		vec4 flixel_unpremultiply_alpha(vec4 color)
		{
			float color_alpha = max(color.a, ALPHA_EPSILON);
			float color_inv_alpha = inversesqrt(color_alpha * color_alpha);

			return vec4(color.rgb * color_inv_alpha, color.a);
		}

		vec4 flixel_premultiply_alpha(vec4 color)
		{
			return vec4(color.rgb * color.a, color.a);
		}

		vec4 flixel_sampleBitmap(sampler2D bitmap, vec2 coord)
		{
			vec4 color = texture2D(bitmap, coord);
			if (premultiplyAlpha)
				color.rgb *= color.a;

			vec4 color_unpremultiplied = flixel_unpremultiply_alpha(color);
			color_unpremultiplied.a = openfl_ColorOffsetv.a + (openfl_ColorMultiplierv.a * color_unpremultiplied.a);

			vec3 offset_color = openfl_ColorOffsetv.rgb;
			vec3 multiply_color = openfl_ColorMultiplierv.rgb;

			color_unpremultiplied.rgb *= multiply_color;
			color_unpremultiplied.rgb += offset_color;

			return flixel_premultiply_alpha(color_unpremultiplied);
		}

		vec4 flixel_texture2D(sampler2D bitmap, vec2 coord)
		{
			return openfl_applyBlend(flixel_sampleBitmap(bitmap, coord));
		}
	", true)
	@:glFragmentSource("
		#pragma header

		void main(void)
		{
			gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
		}
	", true)
	public function new()
	{
		super();
	}
}
